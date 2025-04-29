# ILevelMintingV2Structs
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/interfaces/level/ILevelMintingV2.sol)


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
    uint256 min_lvlusd_amount;
}
```

