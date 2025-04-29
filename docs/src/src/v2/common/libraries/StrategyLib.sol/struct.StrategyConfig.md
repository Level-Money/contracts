# StrategyConfig
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/common/libraries/StrategyLib.sol)


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

