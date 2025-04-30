// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ILevelMintingV2Structs {
    struct Route {
        address[] addresses;
        uint256[] ratios;
    }

    struct Order {
        address beneficiary;
        address collateral_asset;
        uint256 collateral_amount;
        uint256 min_lvlusd_amount;
    }
}

interface ILevelMintingV2Events {
    event Mint(
        address minter,
        address beneficiary,
        address indexed collateral_asset,
        uint256 indexed collateral_amount,
        uint256 indexed min_lvlusd_amount
    );

    event RedeemInitiated(address user, address asset, uint256 collateral_amount, uint256 min_lvlusd_amount);

    event RedeemCompleted(address user, address beneficiary, address asset, uint256 collateralAmount);

    /// @notice Event emitted when the max mint per block is changed
    event MaxMintPerBlockChanged(uint256 indexed oldMaxMintPerBlock, uint256 indexed newMaxMintPerBlock);

    /// @notice Event emitted when the max redeem per block is changed
    event MaxRedeemPerBlockChanged(uint256 indexed oldMaxRedeemPerBlock, uint256 indexed newMaxRedeemPerBlock);

    /// @notice Event emitted when the base collateral is added
    event BaseCollateralUpdated(address indexed asset, bool isBaseCollateral);

    /// @notice Event emitted when a supported asset is added
    event AssetAdded(address indexed asset);

    /// @notice Event emitted when a supported asset is removed
    event AssetRemoved(address indexed asset);

    /// @notice Event emitted when a redeemable asset is added
    event RedeemableAssetAdded(address indexed asset);

    /// @notice Event emitted when a redeemable asset is removed
    event RedeemableAssetRemoved(address indexed asset);

    event ReserveAddressAdded(address reserve);

    event ReserveAddressRemoved(address reserve);

    event CooldownDurationSet(uint256 newduration);

    event HeartBeatSet(address collateral, uint256 heartBeat);

    event OracleAdded(address collateral, address oracle);
    event OracleRemoved(address collateral);

    event VaultManagerSet(address vault, address oldVaultManager);

    event MintRedeemDisabled();

    event DepositDefaultSucceeded(address user, address collateral, uint256 amount);
    event DepositDefaultFailed(address user, address collateral, uint256 amount);

    event WithdrawDefaultSucceeded(address user, address asset, uint256 collateralAmount);
    event WithdrawDefaultFailed(address user, address asset, uint256 collateralAmount);
}

interface ILevelMintingV2Errors {
    error DenyListed();
    error InvalidAmount();
    error InvalidAddress();
    error OraclePriceIsZero();
    error OracleUndefined();
    error InvalidHeartBeatValue();
    error UnsupportedAsset();
    error StillInCooldown();
    error NoPendingRedemptions();
    error MaxMintPerBlockExceeded();
    error MaxRedeemPerBlockExceeded();
    error MinimumlvlUSDAmountNotMet();
    error MinimumCollateralAmountNotMet();
    error HeartBeatNotSet();
    error ExceedsMaxBlockLimit();
    error InvalidCollateral();
    error RedemptionAssetMustBeBaseCollateral();
}

/// @title ILevelMintingV2
/// @notice Interface for the Level Protocol's minting and redemption functionality
/// @dev Inherits events, errors, and structs from respective interfaces
interface ILevelMintingV2 is ILevelMintingV2Events, ILevelMintingV2Errors, ILevelMintingV2Structs {
    /// @notice Mints lvlUSD stablecoin based on the provided order parameters
    /// @param order The Order struct containing mint parameters
    /// @return The amount of lvlUSD minted
    function mint(Order calldata order) external returns (uint256);

    /// @notice Initiates the redemption process for lvlUSD
    /// @param asset The address of the asset to redeem for
    /// @param lvlusdAmount The amount of lvlUSD to redeem
    /// @param minAssetAmount The minimum amount of asset expected to receive
    /// @return lvlUsdAmount The amount of lvlUSD redeemed
    /// @return collateralAmount The amount of collateral redeemed
    function initiateRedeem(address asset, uint256 lvlusdAmount, uint256 minAssetAmount)
        external
        returns (uint256, uint256);

    /// @notice Completes the redemption process after cooldown period
    /// @param asset The address of the asset to redeem for
    /// @param beneficiary The address that will receive the redeemed assets
    /// @return The amount of the asset redeemed
    function completeRedeem(address asset, address beneficiary) external returns (uint256);

    /// @notice Sets the vault manager address
    /// @param _vaultManager The address of the new vault manager
    function setVaultManager(address _vaultManager) external;

    /// @notice Sets the maximum amount that can be minted in a single block
    /// @param _maxMintPerBlock The new maximum mint amount per block
    function setMaxMintPerBlock(uint256 _maxMintPerBlock) external;

    /// @notice Sets the maximum amount that can be redeemed in a single block
    /// @param _maxRedeemPerBlock The new maximum redeem amount per block
    function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external;

    /// @notice Sets the duration of the cooldown period for redemptions
    /// @param newduration The new cooldown duration in seconds
    function setCooldownDuration(uint256 newduration) external;

    /// @notice Disables both minting and redemption functionality
    /// @dev Likely an emergency function restricted to admin or guardian roles
    function disableMintRedeem() external;

    /// @notice Adds an asset to the list of assets that can be used for minting
    /// @param asset The address of the asset to add as mintable
    function addMintableAsset(address asset) external;

    /// @notice Removes an asset from the list of assets that can be used for minting
    /// @param asset The address of the asset to remove from mintable assets
    function removeMintableAsset(address asset) external;

    /// @notice Adds an asset to the list of assets that can be redeemed
    /// @param asset The address of the asset to add as redeemable
    function addRedeemableAsset(address asset) external;

    /// @notice Removes an asset from the list of assets that can be redeemed
    /// @param asset The address of the asset to remove from redeemable assets
    function removeRedeemableAsset(address asset) external;

    /// @notice Sets whether an asset is considered a base collateral
    /// @param asset The address of the asset
    /// @param isBase if the asset should be set as base collateral
    function setBaseCollateral(address asset, bool isBase) external;

    /// @notice Adds a price oracle for a collateral asset
    /// @param collateral The address of the collateral asset
    /// @param oracle The address of the price oracle
    /// @param _isLevelOracle if this is a Level Protocol oracle
    function addOracle(address collateral, address oracle, bool _isLevelOracle) external;

    /// @notice Removes a price oracle for a collateral asset
    /// @param collateral The address of the collateral asset to remove oracle for
    function removeOracle(address collateral) external;

    /// @notice Sets the heartbeat duration (the max time that a price oracle can be stale) for a collateral asset's oracle.
    /// @param collateral The address of the collateral asset
    /// @param heartBeat The new heartbeat duration
    function setHeartBeat(address collateral, uint256 heartBeat) external;
}
