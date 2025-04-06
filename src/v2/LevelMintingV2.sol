// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {Silo} from "@level/src/v2/usd/Silo.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {IlvlUSD} from "@level/src/v2/interfaces/IlvlUSD.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {console2} from "forge-std/console2.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";
import {LevelMintingV2Storage} from "@level/src/v2/LevelMintingV2Storage.sol";
import {PauserGuarded} from "@level/src/v2/common/guard/PauserGuarded.sol";

contract LevelMintingV2 is LevelMintingV2Storage, Initializable, UUPSUpgradeable, AuthUpgradeable, PauserGuarded {
    using MathLib for uint256;

    /* --------------- INITIALIZE --------------- */

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory _assets,
        address[] memory _oracles,
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

        for (uint256 i = 0; i < _assets.length; i++) {
            addMintableAsset(_assets[i]);
            addRedeemableAsset(_assets[i]);
        }

        for (uint256 i = 0; i < _assets.length; i++) {
            addOracle(_assets[i], _oracles[i], false);
        }

        maxMintPerBlock = _maxMintPerBlock;
        maxRedeemPerBlock = _maxRedeemPerBlock;
        cooldownDuration = 5 minutes;

        vaultManager = VaultManager(_vaultManager);
        silo = new Silo(address(this));
    }

    /* --------------- EXTERNAL --------------- */

    function mint(Order calldata order) external requiresAuth notPaused returns (uint256 lvlUsdMinted) {
        if (lvlusd.denylisted(msg.sender)) revert DenyListed();
        verifyOrder(order);

        address underlyingAsset = vaultManager.getAssetFor(order.collateral_asset);
        if (underlyingAsset == address(0)) revert UnsupportedAsset();

        if (isLevelOracle[order.collateral_asset]) {
            bool hasUpdated = OracleLib._tryUpdateOracle(oracles[order.collateral_asset]);
        }

        uint256 underlyingAmount = computeUnderlying(order.collateral_asset, underlyingAsset, order.collateral_amount);

        lvlUsdMinted = computeMint(underlyingAsset, underlyingAmount);

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

        if (vaultManager.getDefaultStrategies(order.collateral_asset).length > 0) {
            vaultManager.depositDefault(order.collateral_asset, order.collateral_amount);
        }

        lvlusd.mint(order.beneficiary, lvlUsdMinted);

        emit Mint(msg.sender, order.beneficiary, order.collateral_asset, order.collateral_amount, order.lvlusd_amount);
    }

    function initiateRedeem(address asset, uint256 lvlUsdAmount, uint256 expectedAmount)
        external
        requiresAuth
        notPaused
        returns (uint256, uint256)
    {
        if (!redeemableAssets[asset]) revert UnsupportedAsset();
        if (lvlUsdAmount == 0) revert InvalidAmount();

        uint256 collateralAmount = computeRedeem(asset, lvlUsdAmount);
        if (collateralAmount < expectedAmount) revert MinimumCollateralAmountNotMet();

        pendingRedemption[msg.sender][asset] += collateralAmount;
        userCooldown[msg.sender][asset] = block.timestamp;

        // note preventing amounts that would fail by definition at complete redeem due to max per block
        if (pendingRedemption[msg.sender][asset] > maxRedeemPerBlock) revert ExceedsMaxBlockLimit();

        lvlusd.burnFrom(msg.sender, lvlUsdAmount);

        try vaultManager.withdrawDefault(asset, collateralAmount) {
            emit WithdrawalSucceeded(msg.sender, asset, collateralAmount);
        } catch {
            emit WithdrawDefaultFailed(msg.sender, asset, collateralAmount);
        }

        vaultManager.vault().exit(
            address(silo), ERC20(asset), collateralAmount, address(vaultManager.vault()), lvlUsdAmount
        );

        emit RedeemInitiated(msg.sender, asset, collateralAmount, lvlUsdAmount);

        return (lvlUsdAmount, collateralAmount);
    }

    // note ABI changed
    function completeRedeem(address asset, address beneficiary) external notPaused returns (uint256 collateralAmount) {
        if (!redeemableAssets[asset]) revert UnsupportedAsset();
        if (userCooldown[msg.sender][asset] + cooldownDuration > block.timestamp) revert StillInCooldown();

        // note we only support complete withdrawal of pending redemptions
        // initiateRedeem can only initiate up to max per block
        collateralAmount = pendingRedemption[msg.sender][asset];
        if (collateralAmount == 0) revert NoPendingRedemptions();

        userCooldown[msg.sender][asset] = 0;
        pendingRedemption[msg.sender][asset] -= collateralAmount;
        redeemedPerBlock[block.number] += collateralAmount;

        silo.withdraw(beneficiary, asset, collateralAmount);

        emit RedeemCompleted(msg.sender, beneficiary, asset, collateralAmount);
    }

    /* --------------- GETTERS/ CHECKS --------------- */

    /// @notice assert validity of order
    function verifyOrder(Order memory order) public view {
        if (!mintableAssets[order.collateral_asset]) revert UnsupportedAsset();
        if (order.beneficiary == address(0)) revert InvalidAmount();
        if (order.collateral_amount == 0) revert InvalidAmount();
    }

    function computeMint(address asset, uint256 collateralAmount) public view returns (uint256 lvlusdAmount) {
        (int256 price, uint256 decimals) = getPriceAndDecimals(asset);

        if (price == 0) {
            revert OraclePriceIsZero();
        }

        uint8 asset_decimals = ERC20(asset).decimals();

        if (uint256(price) < 10 ** decimals) {
            uint256 adjustedCollateralAmount = collateralAmount.mulDivDown(uint256(price), 10 ** decimals);
            return adjustedCollateralAmount.convertDecimalsDown(asset_decimals, LVLUSD_DECIMAL);
        } else {
            return collateralAmount.convertDecimalsDown(asset_decimals, LVLUSD_DECIMAL);
        }
    }

    function computeRedeem(address asset, uint256 lvlusdAmount) public view returns (uint256 collateralAmount) {
        (int256 price, uint256 decimals) = getPriceAndDecimals(asset);
        if (price == 0) {
            revert OraclePriceIsZero();
        }

        uint8 asset_decimals = ERC20(asset).decimals();

        if (uint256(price) > 10 ** decimals) {
            uint256 lvlUsdAdjustedForCollateralPrice = lvlusdAmount.mulDivDown(10 ** decimals, uint256(price));
            return lvlUsdAdjustedForCollateralPrice.convertDecimalsDown(LVLUSD_DECIMAL, asset_decimals);
        } else {
            return lvlusdAmount.convertDecimalsDown(LVLUSD_DECIMAL, asset_decimals);
        }
    }

    // TODO: revisit and cleanup
    function computeUnderlying(address collateral, address underlying, uint256 collateralAmount)
        public
        view
        returns (uint256 underlyingAmount)
    {
        if (isBaseCollateral(collateral)) {
            return collateralAmount;
        } else if (isReceiptToken(collateral)) {
            ERC20 collateralToken = ERC20(collateral);
            ERC20 underlyingToken = ERC20(underlying);

            uint256 collateralAmountWei = collateralAmount.convertDecimalsDown(collateralToken.decimals(), 18);
            (int256 collateralPrice, uint256 decimals) = getPriceAndDecimals(collateral);

            uint256 adjustedCollateralAmountWei =
                collateralAmountWei.mulDivDown(uint256(collateralPrice), 10 ** decimals);

            uint256 underlyingAmount_ = adjustedCollateralAmountWei.convertDecimalsDown(18, underlyingToken.decimals());

            return underlyingAmount_;
        } else {
            revert("Invalid collateral");
        }
    }

    function getPriceAndDecimals(address collateralToken) public view returns (int256 price, uint256 decimal) {
        address oracle = oracles[collateralToken];
        if (oracle == address(0)) {
            revert OracleUndefined();
        }
        uint256 heartBeat = heartbeats[collateralToken];
        if (heartBeat == 0) revert HeartBeatNotSet();

        return OracleLib.getPriceAndDecimals(oracle, heartBeat);
    }

    function isBaseCollateral(address collateral) public view returns (bool) {
        return vaultManager.isBaseCollateral(collateral);
    }

    function isReceiptToken(address collateral) public view returns (bool) {
        return !isBaseCollateral(collateral) && oracles[collateral] != address(0);
    }

    /* --------------- SETTERS --------------- */

    /// @notice Sets the max mintPerBlock limit
    /// Callable by ADMIN_ROLE
    function setMaxMintPerBlock(uint256 _maxMintPerBlock) external requiresAuth {
        _setMaxMintPerBlock(_maxMintPerBlock);
    }

    /// @notice Sets the max redeemPerBlock limit
    /// Callable by ADMIN_ROLE
    function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external requiresAuth {
        _setMaxRedeemPerBlock(_maxRedeemPerBlock);
    }

    /// @notice Disables the mint and redeem
    /// Callable by GATEKEEPER_ROLE and ADMIN_ROLE
    function disableMintRedeem() external requiresAuth {
        _setMaxMintPerBlock(0);
        _setMaxRedeemPerBlock(0);
        emit MintRedeemDisabled();
    }

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

    /// @notice Adds an asset to the supported assets list.
    /// Callable by ADMIN_ROLE (admin timelock)
    function addMintableAsset(address asset) public requiresAuth {
        mintableAssets[asset] = true;
        emit AssetAdded(asset);
    }

    /// @notice Adds an asset to the redeemable assets list.
    /// Callable by ADMIN_ROLE (admin timelock)
    function addRedeemableAsset(address asset) public requiresAuth {
        redeemableAssets[asset] = true;
        emit RedeemableAssetAdded(asset);
    }

    /// @notice Removes an asset from the supported assets list
    // @notice Callable by ADMIN_MULTISIG_ROLE
    function removeMintableAsset(address asset) external requiresAuth {
        mintableAssets[asset] = false;
        emit AssetRemoved(asset);
    }

    /// @notice Removes an asset from the redeemable assets list
    // @notice Callable by ADMIN_MULTISIG_ROLE
    function removeRedeemableAssets(address asset) external requiresAuth {
        redeemableAssets[asset] = false;
        emit RedeemableAssetRemoved(asset);
    }

    function addOracle(address collateral, address oracle, bool _isLevelOracle) public requiresAuth {
        if (oracle == address(0)) revert InvalidAddress();
        oracles[collateral] = oracle;
        isLevelOracle[collateral] = _isLevelOracle;
        emit OracleAdded(collateral, oracle);
    }

    function setHeartBeat(address collateral, uint256 heartBeat) public requiresAuth {
        if (heartBeat == 0) revert InvalidHeartBeatValue();
        heartbeats[collateral] = heartBeat;
        emit HeartBeatSet(collateral, heartBeat);
    }

    function setCooldownDuration(uint256 newduration) external requiresAuth {
        cooldownDuration = newduration;
        emit CooldownDurationSet(newduration);
    }

    function setVaultManager(VaultManager _vault) external requiresAuth {
        address oldVaultManager = address(vaultManager);
        vaultManager = _vault;
        emit VaultManagerSet(address(_vault), oldVaultManager);
    }

    /* --------------- INTERNAL ----------- */

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
