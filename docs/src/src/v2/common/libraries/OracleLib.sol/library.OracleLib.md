# OracleLib
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/common/libraries/OracleLib.sol)


## Functions
### getPriceAndDecimals


```solidity
function getPriceAndDecimals(address oracle, uint256 heartBeat) internal view returns (int256 price, uint256 decimal);
```

### _tryUpdateOracle


```solidity
function _tryUpdateOracle(address _oracle) internal returns (bool isSuccess);
```

