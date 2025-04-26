# PendingLib
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/interfaces/morpho/PendingLib.sol)

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

