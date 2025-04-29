# OracleLib
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/common/libraries/OracleLib.sol)

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

