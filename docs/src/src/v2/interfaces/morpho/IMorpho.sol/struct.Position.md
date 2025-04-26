# Position
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/interfaces/morpho/IMorpho.sol)

*Warning: For `feeRecipient`, `supplyShares` does not contain the accrued shares since the last interest
accrual.*


```solidity
struct Position {
    uint256 supplyShares;
    uint128 borrowShares;
    uint128 collateral;
}
```

