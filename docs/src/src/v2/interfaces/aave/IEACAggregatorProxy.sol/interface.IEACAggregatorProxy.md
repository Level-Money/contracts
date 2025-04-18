# IEACAggregatorProxy
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/aave/IEACAggregatorProxy.sol)


## Functions
### decimals


```solidity
function decimals() external view returns (uint8);
```

### latestAnswer


```solidity
function latestAnswer() external view returns (int256);
```

### latestTimestamp


```solidity
function latestTimestamp() external view returns (uint256);
```

### latestRound


```solidity
function latestRound() external view returns (uint256);
```

### getAnswer


```solidity
function getAnswer(uint256 roundId) external view returns (int256);
```

### getTimestamp


```solidity
function getTimestamp(uint256 roundId) external view returns (uint256);
```

## Events
### AnswerUpdated

```solidity
event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
```

### NewRound

```solidity
event NewRound(uint256 indexed roundId, address indexed startedBy);
```

