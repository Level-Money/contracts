# PauserGuard
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v2/common/guard/PauserGuard.sol)

**Inherits:**
Auth

Abstract contract that provides a flexible pausing mechanism for function selectors

*This contract allows for granular control over function execution through a pausing system.
Functions can be paused individually or as part of a group. Groups are logical collections of
function selectors that can be paused/unpaused together.
The group parameter (bytes32) is expected to be a keccak256 hash of a descriptive string
representing the group's purpose.*


## State Variables
### pausedSelectors
Tracks which selectors are currently paused


```solidity
mapping(address => mapping(bytes4 => bool)) public pausedSelectors;
```


### groupToFunctions
Defines logical groupings of function selectors


```solidity
mapping(bytes32 => FunctionSig[]) public groupToFunctions;
```


### isPausableSelector
Tracks which selectors are configurable (pre-approved)


```solidity
mapping(address => mapping(bytes4 => bool)) public isPausableSelector;
```


## Functions
### constructor


```solidity
constructor(address _owner, Authority _authority) Auth(_owner, _authority);
```

### configureGroup

Configures a group of function selectors that can be paused together

*This function allows the authority to define a logical group of functions
that can be paused/unpaused together. Once configured, all selectors in the group
become pausable. Only callable by authorized addresses (AdminTimelock only)*

*Throws if signatures array is empty or exceeds 255 selectors*


```solidity
function configureGroup(bytes32 group, FunctionSig[] calldata signatures) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`group`|`bytes32`|The keccak256 hash of the group identifier (e.g., keccak256("EMERGENCY_PAUSE"))|
|`signatures`|`FunctionSig[]`|Array of function signatures and their associated contract addresses to be included in the group|


### pauseSelector

Pauses a specific function selector

*Only callable by authorized addresses (must have PAUSER_ROLE)*

*Throws if the selector is not configured as pausable*


```solidity
function pauseSelector(address target, bytes4 selector) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`||
|`selector`|`bytes4`|The function selector to pause|


### unpauseSelector

Unpauses a specific function selector

*Only callable by authorized addresses (must have UNPAUSER_ROLE)*

*Throws if the selector is not currently paused*


```solidity
function unpauseSelector(address target, bytes4 selector) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`||
|`selector`|`bytes4`|The function selector to unpause|


### pauseGroup

Pauses all functions in a configured group

*Only callable by authorized addresses (must have PAUSER_ROLE)*

*Emits events only for selectors that were actually paused*


```solidity
function pauseGroup(bytes32 group) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`group`|`bytes32`|The keccak256 hash of the group identifier|


### unpauseGroup

Unpauses all functions in a configured group

*Only callable by authorized addresses (must have UNPAUSER_ROLE)*

*Emits events only for selectors that were actually unpaused*


```solidity
function unpauseGroup(bytes32 group) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`group`|`bytes32`|The keccak256 hash of the group identifier|


### isPaused

Checks if a specific function selector is paused


```solidity
function isPaused(address target, bytes4 selector) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`||
|`selector`|`bytes4`|The function selector to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the selector is paused, false otherwise|


### getGroupFunctions

Retrieves all function selectors configured for a specific group


```solidity
function getGroupFunctions(bytes32 group) public view returns (FunctionSig[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`group`|`bytes32`|The keccak256 hash of the group identifier|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`FunctionSig[]`|FunctionSig[] Array of function signatures in the group|


## Events
### SelectorPaused

```solidity
event SelectorPaused(address indexed target, bytes4 indexed selector, address indexed by);
```

### SelectorUnpaused

```solidity
event SelectorUnpaused(address indexed target, bytes4 indexed selector, address indexed by);
```

### GroupPaused

```solidity
event GroupPaused(bytes32 indexed group, address indexed by);
```

### GroupUnpaused

```solidity
event GroupUnpaused(bytes32 indexed group, address indexed by);
```

### FunctionSigConfigured

```solidity
event FunctionSigConfigured(bytes32 indexed group, address indexed target, bytes4 selector);
```

## Structs
### FunctionSig
Represents a function signature and its associated contract address


```solidity
struct FunctionSig {
    bytes4 selector;
    address target;
}
```

