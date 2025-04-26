# ILevelMinting
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/interfaces/ILevelMinting.sol)

**Inherits:**
[ILevelMintingEvents](/src/v1/interfaces/ILevelMintingEvents.sol/interface.ILevelMintingEvents.md)


## Functions
### verifyOrder


```solidity
function verifyOrder(Order calldata order) external view returns (bool);
```

### verifyRoute


```solidity
function verifyRoute(Route calldata route, OrderType order_type) external view returns (bool);
```

### mint


```solidity
function mint(Order calldata order, Route calldata route) external;
```

### mintDefault


```solidity
function mintDefault(Order calldata order) external;
```

### initiateRedeem


```solidity
function initiateRedeem(Order memory order) external;
```

### completeRedeem


```solidity
function completeRedeem(address token) external;
```

### getPriceAndDecimals


```solidity
function getPriceAndDecimals(address collateralToken) external view returns (int256, uint256);
```

## Errors
### Duplicate

```solidity
error Duplicate();
```

### InvalidAddress

```solidity
error InvalidAddress();
```

### InvalidlvlUSDAddress

```solidity
error InvalidlvlUSDAddress();
```

### InvalidZeroAddress

```solidity
error InvalidZeroAddress();
```

### InvalidAssetAddress

```solidity
error InvalidAssetAddress();
```

### InvalidReserveAddress

```solidity
error InvalidReserveAddress();
```

### InvalidOrder

```solidity
error InvalidOrder();
```

### InvalidAffirmedAmount

```solidity
error InvalidAffirmedAmount();
```

### InvalidAmount

```solidity
error InvalidAmount();
```

### InvalidRoute

```solidity
error InvalidRoute();
```

### InvalidRatios

```solidity
error InvalidRatios();
```

### UnsupportedAsset

```solidity
error UnsupportedAsset();
```

### NoAssetsProvided

```solidity
error NoAssetsProvided();
```

### InvalidCooldown

```solidity
error InvalidCooldown();
```

### OperationNotAllowed

```solidity
error OperationNotAllowed();
```

### InvalidNonce

```solidity
error InvalidNonce();
```

### TransferFailed

```solidity
error TransferFailed();
```

### MaxMintPerBlockExceeded

```solidity
error MaxMintPerBlockExceeded();
```

### MaxRedeemPerBlockExceeded

```solidity
error MaxRedeemPerBlockExceeded();
```

### MsgSenderIsNotBenefactor

```solidity
error MsgSenderIsNotBenefactor();
```

### OracleUndefined

```solidity
error OracleUndefined();
```

### OraclePriceIsZero

```solidity
error OraclePriceIsZero();
```

### MinimumlvlUSDAmountNotMet

```solidity
error MinimumlvlUSDAmountNotMet();
```

### MinimumCollateralAmountNotMet

```solidity
error MinimumCollateralAmountNotMet();
```

### OraclesLengthNotEqualToAssetsLength

```solidity
error OraclesLengthNotEqualToAssetsLength();
```

## Structs
### Signature

```solidity
struct Signature {
    SignatureType signature_type;
    bytes signature_bytes;
}
```

### Route

```solidity
struct Route {
    address[] addresses;
    uint256[] ratios;
}
```

### Order

```solidity
struct Order {
    OrderType order_type;
    address benefactor;
    address beneficiary;
    address collateral_asset;
    uint256 collateral_amount;
    uint256 lvlusd_amount;
}
```

### UserCooldown

```solidity
struct UserCooldown {
    uint104 cooldownStart;
    Order order;
}
```

## Enums
### Role

```solidity
enum Role {
    Minter,
    Redeemer
}
```

### OrderType

```solidity
enum OrderType {
    MINT,
    REDEEM
}
```

### SignatureType

```solidity
enum SignatureType {
    EIP712
}
```

