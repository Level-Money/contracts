# ILevelMintingEvents
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v1/interfaces/ILevelMintingEvents.sol)


## Events
### Received
Event emitted when contract receives ETH


```solidity
event Received(address, uint256);
```

### Mint
Event emitted when lvlUSD is minted


```solidity
event Mint(
    address minter,
    address benefactor,
    address beneficiary,
    address indexed collateral_asset,
    uint256 indexed collateral_amount,
    uint256 indexed lvlusd_amount
);
```

### Redeem
Event emitted when funds are redeemed


```solidity
event Redeem(
    address redeemer,
    address benefactor,
    address beneficiary,
    address indexed collateral_asset,
    uint256 indexed collateral_amount,
    uint256 indexed lvlusd_amount
);
```

### ReserveWalletAdded
Event emitted when reserve wallet is added


```solidity
event ReserveWalletAdded(address wallet);
```

### ReserveWalletRemoved
Event emitted when a reserve wallet is removed


```solidity
event ReserveWalletRemoved(address wallet);
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

### RedeemableAssetRemoved
Event emitted when a redeemable asset is removed


```solidity
event RedeemableAssetRemoved(address indexed asset);
```

### ReserveAddressAdded

```solidity
event ReserveAddressAdded(address indexed reserve);
```

### ReserveAddressRemoved

```solidity
event ReserveAddressRemoved(address indexed reserve);
```

### ReserveTransfer
Event emitted when assets are moved to reserve provider wallet


```solidity
event ReserveTransfer(address indexed wallet, address indexed asset, uint256 amount);
```

### lvlUSDSet
Event emitted when lvlUSD is set


```solidity
event lvlUSDSet(address indexed lvlUSD);
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

### DelegatedSignerAdded
Event emitted when a delegated signer is added, enabling it to sign orders on behalf of another address


```solidity
event DelegatedSignerAdded(address indexed signer, address indexed delegator);
```

### DelegatedSignerRemoved
Event emitted when a delegated signer is removed


```solidity
event DelegatedSignerRemoved(address indexed signer, address indexed delegator);
```

### RedeemInitiated

```solidity
event RedeemInitiated(address user, address token, uint256 collateral_amount, uint256 lvlusd_amount);
```

### RedeemCompleted

```solidity
event RedeemCompleted(address user, address token, uint256 collateral_amount, uint256 lvlusd_amount);
```

