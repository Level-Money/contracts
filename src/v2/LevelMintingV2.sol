// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {Silo} from "@level/src/v2/usd/Silo.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";
import {LevelMintingV2Storage} from "@level/src/v2/LevelMintingV2Storage.sol";
import {PauserGuarded} from "@level/src/v2/common/guard/PauserGuarded.sol";
import {ILevelMintingV2} from "@level/src/v2/interfaces/level/ILevelMintingV2.sol";

contract LevelMintingV2 is LevelMintingV2Storage, Initializable, UUPSUpgradeable, AuthUpgradeable, PauserGuarded {
    using MathLib for uint256;
    using OracleLib for address;

    /* --------------- INITIALIZE --------------- */

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        uint256 _maxMintPerBlock,
        uint256 _maxRedeemPerBlock,
        address _authority,
        address _vaultManager,
        address _guard
    ) external initializer {
        __UUPSUpgradeable_init();
        __Auth_init(_admin, _authority);
        __PauserGuarded_init(_guard);

        maxMintPerBlock = _maxMintPerBlock;
        maxRedeemPerBlock = _maxRedeemPerBlock;
        cooldownDuration = 5 minutes;

        vaultManager = VaultManager(_vaultManager);
        silo = new Silo(address(this));
    }

    /* --------------- External --------------- */

    /// @inheritdoc ILevelMintingV2
    /// @notice If not public, callable by MINTER_ROLE
    function mint(Order calldata order) external requiresAuth notPaused returns (uint256 lvlUsdMinted) {
        if (lvlusd.denylisted(msg.sender)) revert DenyListed();
        verifyOrder(order);

        if (isLevelOracle[order.collateral_asset]) {
            oracles[order.collateral_asset]._tryUpdateOracle();
        }

        lvlUsdMinted = computeMint(order.collateral_asset, order.collateral_amount);

        mintedPerBlock[block.number] += lvlUsdMinted;

        if (mintedPerBlock[block.number] > maxMintPerBlock) revert ExceedsMaxBlockLimit();
        if (lvlUsdMinted < order.lvlusd_amount) revert MinimumlvlUSDAmountNotMet();

        vaultManager.vault().enter(
            msg.sender,
            ERC20(order.collateral_asset),
            order.collateral_amount,
            address(vaultManager.vault()),
            lvlUsdMinted
        );

        // Don't block mints if deposit default fails
        // If the collateral asset is a receipt token, the underlying call to `vaultManager._deposit`
        // will throw an error, which is caught in the try catch.
        try vaultManager.depositDefault(order.collateral_asset, order.collateral_amount) {
            emit DepositDefaultSucceeded(msg.sender, order.collateral_asset, order.collateral_amount);
        } catch {
            emit DepositDefaultFailed(msg.sender, order.collateral_asset, order.collateral_amount);
        }

        lvlusd.mint(order.beneficiary, lvlUsdMinted);

        emit Mint(msg.sender, order.beneficiary, order.collateral_asset, order.collateral_amount, order.lvlusd_amount);
    }

    /// @inheritdoc ILevelMintingV2
    /// @notice If not public, callable by REDEEMER_ROLE
    /// @dev Redemptions must only occur in base assets
    function initiateRedeem(address asset, uint256 lvlUsdAmount, uint256 expectedAmount)
        external
        requiresAuth
        notPaused
        returns (uint256, uint256)
    {
        if (!redeemableAssets[asset]) revert UnsupportedAsset();
        if (!isBaseCollateral[asset]) revert RedemptionAssetMustBeBaseCollateral();
        if (lvlUsdAmount == 0) revert InvalidAmount();

        uint256 collateralAmount = computeRedeem(asset, lvlUsdAmount);
        if (collateralAmount < expectedAmount) revert MinimumCollateralAmountNotMet();

        pendingRedemption[msg.sender][asset] += collateralAmount;
        userCooldown[msg.sender][asset] = block.timestamp;
        redeemedPerBlock[block.number] += lvlUsdAmount;

        if (redeemedPerBlock[block.number] > maxRedeemPerBlock) revert ExceedsMaxBlockLimit();

        lvlusd.burnFrom(msg.sender, lvlUsdAmount);

        uint256 availableCollateral = ERC20(asset).balanceOf((address(vaultManager.vault())));

        if (availableCollateral < collateralAmount) {
            uint256 toWithdraw = collateralAmount - availableCollateral;
            vaultManager.withdrawDefault(asset, toWithdraw);
        }

        vaultManager.vault().exit(
            address(silo), ERC20(asset), collateralAmount, address(vaultManager.vault()), lvlUsdAmount
        );

        emit RedeemInitiated(msg.sender, asset, collateralAmount, lvlUsdAmount);

        return (lvlUsdAmount, collateralAmount);
    }

    /// @inheritdoc ILevelMintingV2
    /// @dev Collateral sent to the silo may be locked if the address is denylisted after initiating redemption
    function completeRedeem(address asset, address beneficiary) external notPaused returns (uint256 collateralAmount) {
        if (userCooldown[msg.sender][asset] + cooldownDuration > block.timestamp) revert StillInCooldown();
        if (lvlusd.denylisted(msg.sender) || lvlusd.denylisted(beneficiary)) revert DenyListed();

        // note we only support complete withdrawal of pending redemptions
        // initiateRedeem can only initiate up to max per block
        collateralAmount = pendingRedemption[msg.sender][asset];
        if (collateralAmount == 0) revert NoPendingRedemptions();

        userCooldown[msg.sender][asset] = 0;
        pendingRedemption[msg.sender][asset] -= collateralAmount;

        silo.withdraw(beneficiary, asset, collateralAmount);

        emit RedeemCompleted(msg.sender, beneficiary, asset, collateralAmount);
    }

    function setGuard(address _guard) external requiresAuth {
        _setGuard(_guard);
    }

    /* --------------- GETTERS/ CHECKS --------------- */

    /// @notice assert validity of order
    function verifyOrder(Order memory order) public view {
        if (!mintableAssets[order.collateral_asset]) revert UnsupportedAsset();
        if (order.beneficiary == address(0)) revert InvalidAmount();
        if (order.collateral_amount == 0) revert InvalidAmount();

        if (oracles[order.collateral_asset] == address(0)) revert UnsupportedAsset();
    }

    /// @notice Converts collateralAmount to lvlUSD amount to mint
    /// @dev This function could take in either a base collateral (ie USDC/USDT) or a receipt token (ie Morpho vault share, aUSDC/T)
    /// @dev If we receive a receipt token, we need to first convert the receipt token to the amount of underlying it can be redeemd for
    /// @dev before applying the underlying's USD price and calculating the lvlUSD amount to mint
    /// @param collateralAsset The collateral asset to convert
    /// @param collateralAmount The amount of collateral to convert
    /// @return lvlusdAmount The amount of lvlUSD to mint
    function computeMint(address collateralAsset, uint256 collateralAmount)
        public
        view
        returns (uint256 lvlusdAmount)
    {
        address underlyingAsset;

        ERC20 collateralToken = ERC20(collateralAsset);
        uint256 numerator = 10 ** LVLUSD_DECIMAL;
        uint256 denominator = 10 ** collateralToken.decimals();

        if (isBaseCollateral[collateralAsset]) {
            underlyingAsset = collateralAsset;
        } else if (oracles[collateralAsset] != address(0)) {
            underlyingAsset = vaultManager.getUnderlyingAssetFor(collateralAsset);

            (int256 collateralOraclePrice, uint256 collateralOracleDecimals) = getPriceAndDecimals(collateralAsset);

            numerator *= uint256(collateralOraclePrice);
            denominator *= 10 ** collateralOracleDecimals;
        } else {
            revert UnsupportedAsset();
        }

        (int256 underlyingPrice, uint256 underlyingPriceDecimals) = getPriceAndDecimals(underlyingAsset);

        // If stablecoin is under peg, we first multiply the collateral amount by the price before converting to lvlusd amount to mint
        // This helps ensure that lvlUSD is sufficiently collateralized in the event of sharp price movements down
        if (uint256(underlyingPrice) < 10 ** underlyingPriceDecimals) {
            numerator *= uint256(underlyingPrice);
            denominator *= 10 ** underlyingPriceDecimals;
        }

        return collateralAmount.mulDivDown(numerator, denominator);
    }

    /// @notice Converts lvlUSD amount to redeem to collateral amount
    /// @param asset The asset to convert
    /// @param lvlusdAmount The amount of lvlUSD to convert
    /// @return collateralAmount The amount of collateral to redeem
    function computeRedeem(address asset, uint256 lvlusdAmount) public view returns (uint256 collateralAmount) {
        (int256 price, uint256 decimals) = getPriceAndDecimals(asset);

        uint8 asset_decimals = ERC20(asset).decimals();

        // If stablecoin is over peg, we first divide the collateral amount by the price before converting to lvlusd
        // This helps ensure that lvlUSD is sufficiently collateralized in the event of sharp upward price movements
        if (uint256(price) > 10 ** decimals) {
            uint256 lvlUsdAdjustedForCollateralPrice = lvlusdAmount.mulDivDown(10 ** decimals, uint256(price));
            return lvlUsdAdjustedForCollateralPrice.convertDecimalsDown(LVLUSD_DECIMAL, asset_decimals);
        } else {
            return lvlusdAmount.convertDecimalsDown(LVLUSD_DECIMAL, asset_decimals);
        }
    }

    /// @notice Gets the price and decimals of a collateral token
    /// @param collateralToken The collateral token to get the price and decimals for
    /// @return price The price of the collateral token
    /// @return decimal The decimals of the collateral token
    function getPriceAndDecimals(address collateralToken) public view returns (int256 price, uint256 decimal) {
        address oracle = oracles[collateralToken];
        if (oracle == address(0)) {
            revert OracleUndefined();
        }
        uint256 heartBeat = heartbeats[collateralToken];
        if (heartBeat == 0) revert HeartBeatNotSet();

        return oracle.getPriceAndDecimals(heartBeat);
    }

    /* --------------- SETTERS --------------- */

    /// @inheritdoc ILevelMintingV2
    /// @notice Callable by owner
    function setMaxMintPerBlock(uint256 _maxMintPerBlock) external requiresAuth {
        _setMaxMintPerBlock(_maxMintPerBlock);
    }

    /// @inheritdoc ILevelMintingV2
    /// @notice Callable by owner
    function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external requiresAuth {
        _setMaxRedeemPerBlock(_maxRedeemPerBlock);
    }

    /// @inheritdoc ILevelMintingV2
    /// @notice Callable by GATEKEEPER_ROLE and owner
    function disableMintRedeem() external requiresAuth {
        _setMaxMintPerBlock(0);
        _setMaxRedeemPerBlock(0);
        emit MintRedeemDisabled();
    }

    /// @inheritdoc ILevelMintingV2
    /// @notice Callable by owner
    function setBaseCollateral(address asset, bool isBase) external requiresAuth {
        if (asset == address(0)) revert InvalidAddress();
        isBaseCollateral[asset] = isBase;

        emit BaseCollateralUpdated(asset, isBase);
    }

    /// @inheritdoc ILevelMintingV2
    /// @notice Callable by owner
    function addMintableAsset(address asset) public requiresAuth {
        if (asset == address(0)) revert InvalidAddress();
        mintableAssets[asset] = true;
        emit AssetAdded(asset);
    }

    /// @inheritdoc ILevelMintingV2
    /// @notice Callable by owner
    function addRedeemableAsset(address asset) public requiresAuth {
        if (asset == address(0)) revert InvalidAddress();
        redeemableAssets[asset] = true;
        emit RedeemableAssetAdded(asset);
    }

    /// @inheritdoc ILevelMintingV2
    // @notice Callable by ADMIN_MULTISIG_ROLE and owner
    function removeMintableAsset(address asset) external requiresAuth {
        mintableAssets[asset] = false;
        emit AssetRemoved(asset);
    }

    /// @inheritdoc ILevelMintingV2
    // @notice Callable by ADMIN_MULTISIG_ROLE and owner
    function removeRedeemableAsset(address asset) external requiresAuth {
        redeemableAssets[asset] = false;
        emit RedeemableAssetRemoved(asset);
    }

    /// @inheritdoc ILevelMintingV2
    /// @dev Callable by owner
    function addOracle(address collateral, address oracle, bool _isLevelOracle) public requiresAuth {
        if (collateral == address(0) || oracle == address(0)) revert InvalidAddress();
        oracles[collateral] = oracle;
        isLevelOracle[collateral] = _isLevelOracle;
        emit OracleAdded(collateral, oracle);
    }

    /// @inheritdoc ILevelMintingV2
    // @notice Callable by ADMIN_MULTISIG_ROLE and owner
    function removeOracle(address collateral) public requiresAuth {
        oracles[collateral] = address(0);
        isLevelOracle[collateral] = false;
        emit OracleRemoved(collateral);
    }

    /// @inheritdoc ILevelMintingV2
    /// @dev Callable by owner
    function setHeartBeat(address collateral, uint256 heartBeat) public requiresAuth {
        if (heartBeat == 0) revert InvalidHeartBeatValue();
        heartbeats[collateral] = heartBeat;
        emit HeartBeatSet(collateral, heartBeat);
    }

    /// @inheritdoc ILevelMintingV2
    /// @dev Callable by owner
    function setCooldownDuration(uint256 newduration) external requiresAuth {
        cooldownDuration = newduration;
        emit CooldownDurationSet(newduration);
    }

    /// @inheritdoc ILevelMintingV2
    /// @dev Callable by owner
    function setVaultManager(address _vaultManager) external requiresAuth {
        address oldVaultManager = address(vaultManager);
        vaultManager = VaultManager(_vaultManager);
        emit VaultManagerSet(_vaultManager, oldVaultManager);
    }

    /* --------------- INTERNAL ----------- */
    /// @notice Sets the max mintPerBlock limit
    function _setMaxMintPerBlock(uint256 _maxMintPerBlock) internal {
        uint256 oldMaxMintPerBlock = maxMintPerBlock;
        maxMintPerBlock = _maxMintPerBlock;
        emit MaxMintPerBlockChanged(oldMaxMintPerBlock, maxMintPerBlock);
    }

    /// @notice Sets the max redeemPerBlock limit
    function _setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) internal {
        uint256 oldMaxRedeemPerBlock = maxRedeemPerBlock;
        maxRedeemPerBlock = _maxRedeemPerBlock;
        emit MaxRedeemPerBlockChanged(oldMaxRedeemPerBlock, maxRedeemPerBlock);
    }

    /* --------------- UUPS --------------- */

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal override requiresAuth {}
}
