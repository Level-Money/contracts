# StrategyConfig
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/common/libraries/StrategyLib.sol)


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

