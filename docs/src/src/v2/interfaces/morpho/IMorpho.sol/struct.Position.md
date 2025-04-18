# Position
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v2/interfaces/morpho/IMorpho.sol)

*Warning: For `feeRecipient`, `supplyShares` does not contain the accrued shares since the last interest
accrual.*


```solidity
struct Position {
    uint256 supplyShares;
    uint128 borrowShares;
    uint128 collateral;
}
```

