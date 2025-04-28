# PendingLib
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v2/interfaces/morpho/PendingLib.sol)

**Author:**
Morpho Labs

Library to manage pending values and their validity timestamp.

**Note:**
contact: security@morpho.org


## Functions
### update

*Updates `pending`'s value to `newValue` and its corresponding `validAt` timestamp.*

*Assumes `timelock` <= `MAX_TIMELOCK`.*


```solidity
function update(PendingUint192 storage pending, uint184 newValue, uint256 timelock) internal;
```

### update

*Updates `pending`'s value to `newValue` and its corresponding `validAt` timestamp.*

*Assumes `timelock` <= `MAX_TIMELOCK`.*


```solidity
function update(PendingAddress storage pending, address newValue, uint256 timelock) internal;
```

