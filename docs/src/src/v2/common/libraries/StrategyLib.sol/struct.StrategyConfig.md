# StrategyConfig
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v2/common/libraries/StrategyLib.sol)


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

