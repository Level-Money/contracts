# ILevelMintingV2Structs
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v2/interfaces/level/ILevelMintingV2.sol)


## Structs
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
    address beneficiary;
    address collateral_asset;
    uint256 collateral_amount;
    uint256 lvlusd_amount;
}
```

