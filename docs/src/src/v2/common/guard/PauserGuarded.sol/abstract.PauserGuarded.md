# PauserGuarded
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/common/guard/PauserGuarded.sol)

.-==+=======+:
:---=-::-==:
.-:-==-:-==:
.:::--::::::.     .--:-=--:--.       .:--:::--..
.=++=++:::::..     .:::---::--.    ....::...:::.
:::-::..::..      .::::-:::::.     ...::...:::.
...::..::::..     .::::--::-:.    ....::...:::..
............      ....:::..::.    ------:......
...........     ........:....     .....::..:..    ======-......      ...........
:------:.:...   ...:+***++*#+     .------:---.    ...::::.:::...   .....:-----::.
.::::::::-:..   .::--..:-::..    .-=+===++=-==:   ...:::..:--:..   .:==+=++++++*:

An abstract controller that uses a PauserGuard
to control the pause state of the inheriting contract.

*This contract is used to control the pause state of the contract.*


## State Variables
### guard

```solidity
PauserGuard public guard;
```


## Functions
### constructor

*Constructor to initialize the PauserGuard.*


```solidity
constructor(address _guard);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_guard`|`address`|The address of the PauserGuard to use.|


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

