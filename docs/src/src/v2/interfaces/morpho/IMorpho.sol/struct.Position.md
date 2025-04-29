# Position
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/interfaces/morpho/IMorpho.sol)

*Warning: For `feeRecipient`, `supplyShares` does not contain the accrued shares since the last interest
accrual.*


```solidity
struct Position {
    uint256 supplyShares;
    uint128 borrowShares;
    uint128 collateral;
}
```

