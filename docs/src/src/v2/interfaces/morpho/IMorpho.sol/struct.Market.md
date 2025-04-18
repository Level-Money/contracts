# Market
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/morpho/IMorpho.sol)

*Warning: `totalSupplyAssets` does not contain the accrued interest since the last interest accrual.*

*Warning: `totalBorrowAssets` does not contain the accrued interest since the last interest accrual.*

*Warning: `totalSupplyShares` does not contain the additional shares accrued by `feeRecipient` since the last
interest accrual.*


```solidity
struct Market {
    uint128 totalSupplyAssets;
    uint128 totalSupplyShares;
    uint128 totalBorrowAssets;
    uint128 totalBorrowShares;
    uint128 lastUpdate;
    uint128 fee;
}
```

