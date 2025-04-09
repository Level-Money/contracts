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
        uint256 lvlusd_amount;
    }
}

interface ILevelMintingV2Events {
    event Mint(
        address minter,
        address beneficiary,
        address indexed collateral_asset,
        uint256 indexed collateral_amount,
        uint256 indexed lvlusd_amount
    );

    event RedeemInitiated(address user, address asset, uint256 collateral_amount, uint256 lvlusd_amount);

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

interface ILevelMintingV2 is ILevelMintingV2Events, ILevelMintingV2Errors, ILevelMintingV2Structs {
    function mint(Order calldata order) external returns (uint256);

    function initiateRedeem(address asset, uint256 lvlusdAmount, uint256 expectedAmount)
        external
        returns (uint256, uint256);

    function completeRedeem(address asset, address beneficiary) external returns (uint256);

    function setVaultManager(address _vaultManager) external;
    function setMaxMintPerBlock(uint256 _maxMintPerBlock) external;
    function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external;
    function setCooldownDuration(uint256 newduration) external;
    function disableMintRedeem() external;
    function addMintableAsset(address asset) external;
    function removeMintableAsset(address asset) external;
    function addRedeemableAsset(address asset) external;
    function removeRedeemableAsset(address asset) external;
    function setBaseCollateral(address asset, bool isBase) external;
    function addOracle(address collateral, address oracle, bool _isLevelOracle) external;
    function removeOracle(address collateral) external;
    function setHeartBeat(address collateral, uint256 heartBeat) external;
}
