# IlvlUSDDefinitions
[Git Source](https://github.com/Level-Money/contracts/blob/7fc97def4c32b2c55e844838ecbb532dceb8179d/src/interfaces/IlvlUSDDefinitions.sol)

*Changelog: changed solidity version and name*


## Events
### MinterUpdated
This event is fired when the minter changes


```solidity
event MinterUpdated(address indexed newMinter, address indexed oldMinter);
```

### SlasherUpdated
This event is fired when the slasher changes


```solidity
event SlasherUpdated(address indexed newSlasher, address indexed oldSlasher);
```

## Errors
### ZeroAddressException
Zero address not allowed


```solidity
error ZeroAddressException();
```

### OperationNotAllowed
It's not possible to renounce the ownership


```solidity
error OperationNotAllowed();
```

### OnlyMinter
Only the minter role can perform an action


```solidity
error OnlyMinter();
```

### Denylisted
Address is denylisted


```solidity
error Denylisted();
```

### IsOwner
Address is owner


```solidity
error IsOwner();
```

