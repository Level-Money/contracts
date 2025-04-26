# AaveTokenOracle
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/oracles/AaveTokenOracle.sol)

**Inherits:**
[AggregatorV3Interface](/src/v1/interfaces/AggregatorV3Interface.sol/interface.AggregatorV3Interface.md)


## State Variables
### underlying

```solidity
IERC20Metadata public immutable underlying;
```


## Functions
### constructor


```solidity
constructor(address _underlying);
```

### decimals


```solidity
function decimals() external view returns (uint8);
```

### description


```solidity
function description() external pure returns (string memory);
```

### version


```solidity
function version() external pure returns (uint256);
```

### getRoundData


```solidity
function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80);
```

### latestRoundData


```solidity
function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
```

