// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

/**
 * solhint-disable private-vars-leading-underscore
 */

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./SingleAdminAccessControl.sol";
import "./interfaces/IStakedlvlUSDCooldown.sol";
import "./slvlUSDSilo.sol";
import "./Freezer.sol";

/**
 * @title StakedlvlUSD
 * @notice The StakedlvlUSD contract allows users to stake lvlUSD and earn a portion of protocol perpetual yield that is allocated
 * to stakers by the Level DAO governance voted yield distribution algorithm. The algorithm seeks to balance the stability of the
 * the protocol's insurance fund, DAO activities, and rewarding stakers with a portion of the protocol's yield.
 * @dev Changelog: change references to LevelMinting and lvlUSD, update solidity versions
 */
contract StakedlvlUSD is
    SingleAdminAccessControl,
    ReentrancyGuard,
    ERC20Permit,
    ERC4626,
    IStakedlvlUSDCooldown
{
    using SafeERC20 for IERC20;
    mapping(address => UserCooldown) public cooldowns;

    /* ------------- CONSTANTS ------------- */
    /// @notice The role that is allowed to distribute rewards to this contract
    bytes32 private constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

    /// @notice The role that is allowed to freeze (transfer funds to freezer contract) and unfreeze (transfer funds from freeze contract) funds
    bytes32 private constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

    /// @notice The role that is allowed to denylist and un-denylist addresses
    bytes32 private constant DENYLIST_MANAGER_ROLE =
        keccak256("DENYLIST_MANAGER_ROLE");
    /// @notice The role which prevents an address to stake
    bytes32 private constant SOFT_RESTRICTED_STAKER_ROLE =
        keccak256("SOFT_RESTRICTED_STAKER_ROLE");
    /// @notice The role which prevents an address to transfer, stake, or unstake. The owner of the contract can redirect address staking balance if an address is in full restricting mode.
    bytes32 private constant FULL_RESTRICTED_STAKER_ROLE =
        keccak256("FULL_RESTRICTED_STAKER_ROLE");

    /// @notice The vesting period of lastDistributionAmount over which it increasingly becomes available to stakers
    uint256 private constant VESTING_PERIOD = 8 hours; // TODO: make sure this to 8 hours in prod
    uint256 private constant UNFREEZING_PERIOD = 8 hours; // TODO: make sure this to 8 hours in prod
    /// @notice Minimum non-zero shares amount to prevent donation attack
    uint256 private constant MIN_SHARES = 1 ether; // TODO: make sure this 1 ether in prod

    uint24 public constant MAX_COOLDOWN_DURATION = 90 days;

    uint16 constant MAX_FREEZABLE_PERCENTAGE = 5_000; // 50%

    /* ------------- Errors ------------- */
    error MaxFreezablePercentage();

    /* ------------- STATE VARIABLES ------------- */
    uint24 public cooldownDuration;
    slvlUSDSilo public immutable silo;
    Freezer public immutable freezer;

    /// @notice The amount of the last asset distribution from the controller contract into this
    /// contract + any unvested remainder at that time
    uint256 public vestingAmount;

    /// @notice The amount of the last asset distribution from the freezer contract into this
    /// contract + any unvested remainder at that time
    uint256 public unfreezingAmount;

    /// @notice The timestamp of the last asset distribution from the controller contract into this contract
    uint256 public lastDistributionTimestamp;

    uint256 public lastUnfreezingTimestamp;

    /// @notice Percentage of the reserves that can remain frozen at any given time.
    /// Has 2 decimal places, so 100% is represented as 10000; value can be anywhere
    /// between 0 and 10000.
    uint16 public freezablePercentage;

    /* ------------- MODIFIERS ------------- */

    /// @notice ensure input amount nonzero
    modifier notZero(uint256 amount) {
        if (amount == 0) revert InvalidAmount();
        _;
    }

    /// @notice ensures denylist target is not owner
    modifier notOwner(address target) {
        if (target == owner()) revert CantDenylistOwner();
        _;
    }

    /* ------------- CONSTRUCTOR ------------- */

    /**
     * @notice Constructor for StakedlvlUSD contract.
     * @param _asset The address of the lvlUSD token.
     * @param _initialRewarder The address of the initial rewarder.
     * @param _owner The address of the admin role.
     *
     */
    constructor(
        IERC20 _asset,
        address _initialRewarder,
        address _owner
    ) ERC20("Staked lvlUSD", "slvlUSD") ERC4626(_asset) ERC20Permit("slvlUSD") {
        if (
            _owner == address(0) ||
            _initialRewarder == address(0) ||
            address(_asset) == address(0)
        ) {
            revert InvalidZeroAddress();
        }

        _grantRole(REWARDER_ROLE, _initialRewarder);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        silo = new slvlUSDSilo(address(this));
        freezer = new Freezer(address(this), address(_asset));
    }

    /* ------------- EXTERNAL ------------- */

    /**
     * @notice Allows the owner to transfer rewards from the controller contract into this contract.
     * @param amount The amount of rewards to transfer.
     */
    function transferInRewards(
        uint256 amount
    ) external nonReentrant onlyRole(REWARDER_ROLE) notZero(amount) {
        if (getUnvestedAmount() > 0) revert StillVesting();
        uint256 newVestingAmount = amount;

        vestingAmount = newVestingAmount;
        lastDistributionTimestamp = block.timestamp;
        // transfer assets from rewarder to this contract
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);

        emit RewardsReceived(amount);
    }

    /**
     * @notice Allows the freezer to transfer assets from the freezer contract into this contract.
     * @param amount The amount of frozen assets to transfer.
     */
    function transferInFrozenFunds(
        uint256 amount
    ) external nonReentrant onlyRole(FREEZER_ROLE) notZero(amount) {
        if (getUnvestedUnfrozenAmount() > 0) revert StillVesting();
        uint256 newUnfreezingAmount = amount;

        unfreezingAmount = newUnfreezingAmount;
        lastUnfreezingTimestamp = block.timestamp;

        // transfer assets from freezer to this contract
        freezer.withdraw(amount);

        emit FrozenFundsReceived(amount);
    }

    /**
     * @notice Allows someone with the freezer role to transfer assets from this contract to the freezer
     * @param amount The amount of assets to freeze.
     */
    function freeze(
        uint256 amount
    ) external nonReentrant onlyRole(FREEZER_ROLE) notZero(amount) {
        uint256 alreadyFrozen = IERC20(asset()).balanceOf(address(freezer));
        uint256 toFreeze = alreadyFrozen + amount;

        uint256 freezable = getFreezableAmount();
        if (toFreeze > freezable) revert ExceedsFreezable();

        IERC20(asset()).transfer(address(freezer), amount);
    }

    /**
     * @notice Returns the freezable amount of assets.
     * @return The freezable amount of assets.
     */
    function getFreezableAmount() public view returns (uint256) {
        uint256 frozenAssets = IERC20(asset()).balanceOf(address(freezer));
        return ((totalAssets() + frozenAssets) * freezablePercentage) / 10_000;
    }

    /**
     * @notice Allows the owner (DEFAULT_ADMIN_ROLE) and denylist managers to denylist addresses.
     * @param target The address to denylist.
     * @param isFullDenylisting Soft or full denylisting level.
     */
    function addToDenylist(
        address target,
        bool isFullDenylisting
    ) external onlyRole(DENYLIST_MANAGER_ROLE) notOwner(target) {
        bytes32 role = isFullDenylisting
            ? FULL_RESTRICTED_STAKER_ROLE
            : SOFT_RESTRICTED_STAKER_ROLE;
        _grantRole(role, target);
    }

    /**
     * @notice Allows the owner (DEFAULT_ADMIN_ROLE) and denylist managers to un-denylist addresses.
     * @param target The address to un-denylist.
     * @param isFullDenylisting Soft or full denylisting level.
     */
    function removeFromDenylist(
        address target,
        bool isFullDenylisting
    ) external onlyRole(DENYLIST_MANAGER_ROLE) notOwner(target) {
        bytes32 role = isFullDenylisting
            ? FULL_RESTRICTED_STAKER_ROLE
            : SOFT_RESTRICTED_STAKER_ROLE;
        _revokeRole(role, target);
    }

    /**
     * @notice Allows the owner to rescue tokens accidentally sent to the contract.
     * Note that the owner cannot rescue lvlUSD tokens but can rescue staked lvlUSD
     * as they should never actually sit in this contract and a staker may well
     * transfer them here by accident.
     * @param token The token to be rescued.
     * @param amount The amount of tokens to be rescued.
     * @param to Where to send rescued tokens
     */
    function rescueTokens(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(token) == asset() && totalSupply() != 0)
            revert InvalidToken();
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Burns the full restricted user amount and mints to the desired owner address.
     * @param from The address to burn the entire balance, with the FULL_RESTRICTED_STAKER_ROLE
     * @param to The address to mint the entire balance of "from" parameter.
     */
    function redistributeLockedAmount(
        address from,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            hasRole(FULL_RESTRICTED_STAKER_ROLE, from) &&
            !hasRole(FULL_RESTRICTED_STAKER_ROLE, to)
        ) {
            uint256 amountInEOA = balanceOf(from);
            _burn(from, amountInEOA);

            uint256 amountInSilo = cooldowns[from].underlyingShares;
            if (amountInSilo != 0) {
                _burn(address(silo), amountInSilo);
                delete cooldowns[from];
            }

            uint256 amountToDistribute = amountInEOA + amountInSilo;
            // to address of address(0) enables burning
            if (to != address(0)) _mint(to, amountToDistribute);

            emit LockedAmountRedistributed(from, to, amountToDistribute);
        } else {
            revert OperationNotAllowed();
        }
    }

    /* ------------- PUBLIC ------------- */

    /**
     * @notice Returns the amount of lvlUSD tokens that are vested in the contract.
     */
    function totalAssets() public view override returns (uint256) {
        return
            IERC20(asset()).balanceOf(address(this)) -
            getUnvestedAmount() -
            getUnvestedUnfrozenAmount();
    }

    /**
     * @notice Returns the amount of lvlUSD tokens that are unvested in the contract.
     */
    function getUnvestedAmount() public view returns (uint256) {
        uint256 timeSinceLastDistribution = block.timestamp -
            lastDistributionTimestamp;

        if (timeSinceLastDistribution >= VESTING_PERIOD) {
            return 0;
        }

        return
            ((VESTING_PERIOD - timeSinceLastDistribution) * vestingAmount) /
            VESTING_PERIOD;
    }

    /**
     * @notice Returns the amount of lvlUSD tokens that are unvested in the contract.
     */
    function getUnvestedUnfrozenAmount() public view returns (uint256) {
        uint256 timeSinceLastUnfreezing = block.timestamp -
            lastUnfreezingTimestamp;

        if (timeSinceLastUnfreezing >= UNFREEZING_PERIOD) {
            return 0;
        }

        return
            ((UNFREEZING_PERIOD - timeSinceLastUnfreezing) * unfreezingAmount) /
            UNFREEZING_PERIOD;
    }

    /// @dev Necessary because both ERC20 (from ERC20Permit) and ERC4626 declare decimals()
    function decimals() public pure override(ERC4626, ERC20) returns (uint8) {
        return 18;
    }

    /// @dev check how much caller's siloed shares are worth in terms of assets
    function previewEscrow() public view returns (uint256) {
        uint256 escrowedShares = cooldowns[msg.sender].underlyingShares;
        return previewRedeem(escrowedShares);
    }

    /* ------------- INTERNAL ------------- */

    /// @notice ensures a small non-zero amount of shares does not remain, exposing to donation attack
    function _checkMinShares() internal view {
        uint256 _totalSupply = totalSupply() - balanceOf(address(silo));
        if (_totalSupply > 0 && _totalSupply < MIN_SHARES)
            revert MinSharesViolation();
    }

    /**
     * @dev Deposit/mint common workflow.
     * @param caller sender of assets
     * @param receiver where to send shares
     * @param assets assets to deposit
     * @param shares shares to mint
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override nonReentrant notZero(assets) notZero(shares) {
        if (
            hasRole(SOFT_RESTRICTED_STAKER_ROLE, caller) ||
            hasRole(SOFT_RESTRICTED_STAKER_ROLE, receiver)
        ) {
            revert OperationNotAllowed();
        }
        super._deposit(caller, receiver, assets, shares);
        _checkMinShares();
    }

    /**
     * @dev Part of cooldownAssets/cooldownShares withdraw-to-Silo workflow (no burning involved).
     * @param caller tx sender
     * @param receiver where to send assets
     * @param _owner where to burn shares from
     * @param shares shares to burn
     */
    function _escrow(
        address caller,
        address receiver,
        address _owner,
        uint256 shares
    ) internal nonReentrant notZero(shares) {
        if (
            hasRole(FULL_RESTRICTED_STAKER_ROLE, caller) ||
            hasRole(FULL_RESTRICTED_STAKER_ROLE, receiver)
        ) {
            revert OperationNotAllowed();
        }

        // check that caller has sufficient allowance to spend on behalf of _owner
        if (caller != _owner) {
            super._spendAllowance(_owner, caller, shares);
        }

        super._transfer(_owner, receiver, shares);
        _checkMinShares();
    }

    /**
     * @dev Part of ERC4626 withdraw/redeem common workflow. Withdraw assets to receiver after burning _owner-held shares.
     * @param caller tx sender
     * @param receiver where to send assets
     * @param _owner where to burn shares from
     * @param assets asset amount to transfer out
     * @param shares shares to burn
     */
    function _withdraw(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint256 shares
    ) internal override nonReentrant notZero(assets) notZero(shares) {
        if (
            hasRole(FULL_RESTRICTED_STAKER_ROLE, caller) ||
            hasRole(FULL_RESTRICTED_STAKER_ROLE, _owner) ||
            hasRole(FULL_RESTRICTED_STAKER_ROLE, receiver)
        ) {
            revert OperationNotAllowed();
        }

        super._withdraw(caller, receiver, _owner, assets, shares);
        _checkMinShares();
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning. Disables transfers from or to of addresses with the FULL_RESTRICTED_STAKER_ROLE role.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (hasRole(FULL_RESTRICTED_STAKER_ROLE, from) && to != address(0)) {
            revert OperationNotAllowed();
        }
        if (hasRole(FULL_RESTRICTED_STAKER_ROLE, to)) {
            revert OperationNotAllowed();
        }
    }

    /**
     * @dev Remove renounce role access from AccessControl, to prevent users to resign roles.
     */
    function renounceRole(bytes32, address) public virtual override {
        revert OperationNotAllowed();
    }

    /// @notice ensure cooldownDuration is zero
    modifier ensureCooldownOff() {
        if (cooldownDuration != 0) revert OperationNotAllowed();
        _;
    }

    /// @notice ensure cooldownDuration is gt 0
    modifier ensureCooldownOn() {
        if (cooldownDuration == 0) revert OperationNotAllowed();
        _;
    }

    /* ------------- EXTERNAL ------------- */

    /**
     * @dev See {IERC4626-withdraw}.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override ensureCooldownOff returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @dev See {IERC4626-redeem}.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override ensureCooldownOff returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    /// @notice Claim the staking amount after the cooldown has finished. The address can only retire the full amount of assets.
    /// @dev unstake can be called after cooldown have been set to 0, to let accounts to be able to claim assets equivalent in value to shares locked at Silo
    /// @param receiver Address to send the assets by the staker
    /// Note: super.redeem calls our private implementation of _withdraw, which is nonReentrant, so this function should also be nonReentrant
    function unstake(address receiver) external {
        UserCooldown storage userCooldown = cooldowns[msg.sender];
        uint256 shares = userCooldown.underlyingShares;
        uint256 cooldownEnd = userCooldown.cooldownStart + cooldownDuration;
        if (block.timestamp >= cooldownEnd) {
            // withdraw slvlUSD to the user
            silo.withdraw(msg.sender, shares);

            // burn slvlUSD from the user, and send corresponding amount of assets to receiver
            uint256 assets = previewRedeem(shares);
            if (userCooldown.expectedAssets < assets)
                assets = userCooldown.expectedAssets;
            _withdraw(msg.sender, receiver, msg.sender, assets, shares);
            userCooldown.cooldownStart = 0;
            userCooldown.underlyingShares = 0;
            userCooldown.expectedAssets = 0;
        } else {
            revert InvalidCooldown();
        }
    }

    /// @notice redeem assets and starts a cooldown to claim the converted underlying asset
    /// @param assets assets to redeem
    /// @param owner address to redeem and start cooldown, owner must allowed caller to perform this action
    function cooldownAssets(
        uint256 assets,
        address owner
    ) external ensureCooldownOn returns (uint256) {
        if (assets > maxWithdraw(owner)) revert ExcessiveWithdrawAmount();

        uint256 shares = previewWithdraw(assets);

        cooldowns[owner].cooldownStart = uint104(block.timestamp);
        cooldowns[owner].underlyingShares += shares;
        cooldowns[owner].expectedAssets += assets;

        _escrow(_msgSender(), address(silo), owner, shares);

        return shares;
    }

    /// @notice redeem shares into assets and starts a cooldown to claim the converted underlying asset
    /// @param shares shares to redeem
    /// @param owner address to redeem and start cooldown, owner must allowed caller to perform this action
    /// @return assets the estimated amount of assets that can be redeemed from shares (this may change during the cooldown period)
    function cooldownShares(
        uint256 shares,
        address owner
    ) external ensureCooldownOn returns (uint256) {
        if (shares > maxRedeem(owner)) revert ExcessiveRedeemAmount();

        // TODO: Keep this as a current preview? It's not guaranteed to be amount of redeemable assets later on.
        //       due to freezing / unfreezing events.
        uint256 assets = previewRedeem(shares);

        cooldowns[owner].cooldownStart = uint104(block.timestamp);
        cooldowns[owner].underlyingShares += shares;
        cooldowns[owner].expectedAssets += assets;

        // withdraw should send _transfer instead of _burn shares from the msg sender's account
        // what other functionalities does _withdraw implement?
        _escrow(_msgSender(), address(silo), owner, shares);

        return assets;
    }

    /// @notice Set cooldown duration. If cooldown duration is set to zero, the StakedlvlUSD behavior changes to follow ERC4626 standard and disables cooldownShares and cooldownAssets methods. If cooldown duration is greater than zero, the ERC4626 withdrawal and redeem functions are disabled, breaking the ERC4626 standard, and enabling the cooldownShares and the cooldownAssets functions.
    /// @param duration Duration of the cooldown
    function setCooldownDuration(
        uint24 duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (duration > MAX_COOLDOWN_DURATION) {
            revert InvalidCooldown();
        }

        uint24 previousDuration = cooldownDuration;
        cooldownDuration = duration;
        emit CooldownDurationUpdated(previousDuration, cooldownDuration);
    }

    /// @notice Set percentage of the reserves that can remain frozen at any given time.
    /// @param percentage Percentage of the reserves that can remain frozen at any given time.
    function setFreezablePercentage(
        uint16 percentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (percentage > MAX_FREEZABLE_PERCENTAGE)
            revert MaxFreezablePercentage();
        uint16 previousFreezable = freezablePercentage;
        freezablePercentage = percentage;

        emit FreezablePercentageUpdated(previousFreezable, percentage);
    }
}
