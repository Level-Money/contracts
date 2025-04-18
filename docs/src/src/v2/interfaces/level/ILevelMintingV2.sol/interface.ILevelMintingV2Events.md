# ILevelMintingV2Events
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/level/ILevelMintingV2.sol)


## Events
### Mint

```solidity
event Mint(
    address minter,
    address beneficiary,
    address indexed collateral_asset,
    uint256 indexed collateral_amount,
    uint256 indexed lvlusd_amount
);
```

### RedeemInitiated

```solidity
event RedeemInitiated(address user, address asset, uint256 collateral_amount, uint256 lvlusd_amount);
```

### RedeemCompleted

```solidity
event RedeemCompleted(address user, address beneficiary, address asset, uint256 collateralAmount);
```

### MaxMintPerBlockChanged
Event emitted when the max mint per block is changed


```solidity
event MaxMintPerBlockChanged(uint256 indexed oldMaxMintPerBlock, uint256 indexed newMaxMintPerBlock);
```

### MaxRedeemPerBlockChanged
Event emitted when the max redeem per block is changed


```solidity
event MaxRedeemPerBlockChanged(uint256 indexed oldMaxRedeemPerBlock, uint256 indexed newMaxRedeemPerBlock);
```

### BaseCollateralUpdated
Event emitted when the base collateral is added


```solidity
event BaseCollateralUpdated(address indexed asset, bool isBaseCollateral);
```

### AssetAdded
Event emitted when a supported asset is added


```solidity
event AssetAdded(address indexed asset);
```

### AssetRemoved
Event emitted when a supported asset is removed


```solidity
event AssetRemoved(address indexed asset);
```

### RedeemableAssetAdded
Event emitted when a redeemable asset is added


```solidity
event RedeemableAssetAdded(address indexed asset);
```

### RedeemableAssetRemoved
Event emitted when a redeemable asset is removed


```solidity
event RedeemableAssetRemoved(address indexed asset);
```

### ReserveAddressAdded

```solidity
event ReserveAddressAdded(address reserve);
```

### ReserveAddressRemoved

```solidity
event ReserveAddressRemoved(address reserve);
```

### CooldownDurationSet

```solidity
event CooldownDurationSet(uint256 newduration);
```

### HeartBeatSet

```solidity
event HeartBeatSet(address collateral, uint256 heartBeat);
```

### OracleAdded

```solidity
event OracleAdded(address collateral, address oracle);
```

### OracleRemoved

```solidity
event OracleRemoved(address collateral);
```

### VaultManagerSet

```solidity
event VaultManagerSet(address vault, address oldVaultManager);
```

### MintRedeemDisabled

```solidity
event MintRedeemDisabled();
```

### DepositDefaultSucceeded

```solidity
event DepositDefaultSucceeded(address user, address collateral, uint256 amount);
```

### DepositDefaultFailed

```solidity
event DepositDefaultFailed(address user, address collateral, uint256 amount);
```

### WithdrawDefaultSucceeded

```solidity
event WithdrawDefaultSucceeded(address user, address asset, uint256 collateralAmount);
```

### WithdrawDefaultFailed

```solidity
event WithdrawDefaultFailed(address user, address asset, uint256 collateralAmount);
```

