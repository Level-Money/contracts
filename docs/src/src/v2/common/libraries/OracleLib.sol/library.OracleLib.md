# OracleLib
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/common/libraries/OracleLib.sol)


## Functions
### getPriceAndDecimals


```solidity
function getPriceAndDecimals(address oracle, uint256 heartBeat) internal view returns (int256 price, uint256 decimal);
```

### _tryUpdateOracle


```solidity
function _tryUpdateOracle(address _oracle) internal returns (bool isSuccess);
```

