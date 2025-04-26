# PauserGuarded
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/common/guard/PauserGuarded.sol)

**Inherits:**
Initializable

An abstract controller that uses a PauserGuard
to control the pause state of the inheriting contract.

*This contract is used to control the pause state of the contract.*


## State Variables
### guard

```solidity
PauserGuard public guard;
```


### __gap
*This empty reserved space is put in place to allow future versions to add new
variables without shifting down storage in the inheritance chain.
See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps*


```solidity
uint256[35] private __gap;
```


## Functions
### __PauserGuarded_init

*Initializes the contract with a PauserGuard.*


```solidity
function __PauserGuarded_init(address _guard) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_guard`|`address`|The guard that controls the pause state of the contract.|


### notPaused

*Modifier to check if the contract is paused.*

*Throws if the contract is paused.*


```solidity
modifier notPaused();
```

### isPaused

*Returns true if the contract is paused.*


```solidity
function isPaused(address target, bytes4 selector) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`||
|`selector`|`bytes4`|The selector of the function to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the contract is paused, false otherwise.|


### _setGuard

*Contracts that call this function should implement this function with their own access control*

**Note:**
auditnote: is there anyway to throw a warning or an error if this function is not called by a child contract?


```solidity
function _setGuard(address _guard) internal virtual;
```

## Events
### PauserGuardUpdated

```solidity
event PauserGuardUpdated(address indexed oldGuard, address indexed newGuard);
```

## Errors
### Paused

```solidity
error Paused();
```

