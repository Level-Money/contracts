# StrategyConfig
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/common/libraries/StrategyLib.sol)


```solidity
struct StrategyConfig {
    StrategyCategory category;
    ERC20 baseCollateral;
    ERC20 receiptToken;
    AggregatorV3Interface oracle;
    address depositContract;
    address withdrawContract;
    uint256 heartbeat;
}
```

