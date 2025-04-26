# Market
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/interfaces/morpho/IMorpho.sol)

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

