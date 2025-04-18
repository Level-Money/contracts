# StrategyConfig
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/common/libraries/StrategyLib.sol)


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

