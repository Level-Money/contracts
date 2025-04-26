# ILevelMintingV2Structs
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/interfaces/level/ILevelMintingV2.sol)


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

