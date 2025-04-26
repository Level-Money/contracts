# ILevelMintingV2Structs
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/interfaces/level/ILevelMintingV2.sol)


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

