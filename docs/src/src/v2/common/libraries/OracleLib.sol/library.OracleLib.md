# OracleLib
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/common/libraries/OracleLib.sol)


## Functions
### getPriceAndDecimals


```solidity
function getPriceAndDecimals(address oracle, uint256 heartBeat) internal view returns (int256 price, uint256 decimal);
```

### _tryUpdateOracle


```solidity
function _tryUpdateOracle(address _oracle) internal returns (bool isSuccess);
```

