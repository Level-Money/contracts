# ILevelMintingV2Structs
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/level/ILevelMintingV2.sol)


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

