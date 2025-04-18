# Position
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/morpho/IMorpho.sol)

*Warning: For `feeRecipient`, `supplyShares` does not contain the accrued shares since the last interest
accrual.*


```solidity
struct Position {
    uint256 supplyShares;
    uint128 borrowShares;
    uint128 collateral;
}
```

