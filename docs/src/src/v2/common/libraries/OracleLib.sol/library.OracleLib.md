# OracleLib
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/common/libraries/OracleLib.sol)

**Author:**
Level (https://level.money)

Library to manage oracle operations


## Functions
### getPriceAndDecimals


```solidity
function getPriceAndDecimals(address oracle, uint256 heartBeat) internal view returns (int256 price, uint256 decimal);
```

### _tryUpdateOracle


```solidity
function _tryUpdateOracle(address _oracle) internal returns (bool isSuccess);
```

