# StrictRolesAuthority
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/auth/StrictRolesAuthority.sol)

**Inherits:**
RolesAuthority

An extension of RolesAuthority that enforces stricter role management rules

*This contract only allows adding roles through setUserRole() and requires admin multisig
approval for role removal through removeUserRole()*


## State Variables
### isRoleRemovable
Which roles are allowed to be removed


```solidity
mapping(uint8 => bool) public isRoleRemovable;
```


## Functions
### constructor

Creates a new StrictRolesAuthority instance


```solidity
constructor(address _owner, Authority _authority) RolesAuthority(_owner, _authority);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|The address that will be the owner of this authority|
|`_authority`|`Authority`|The authority contract to use for authentication|


### setUserRole

Sets a role for a user, but only allows adding roles

*This function can only be called by authorized addresses*

**Note:**
reverts: If enabled is false or caller is not authorized


```solidity
function setUserRole(address user, uint8 role, bool enabled) public virtual override requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to set the role for|
|`role`|`uint8`|The role to set|
|`enabled`|`bool`|Must be true, as this function only allows adding roles|


### removeUserRole

Removes a role from a user

*This function can only be called by called by the ADMIN_MULTISIG_ROLE*

**Note:**
reverts: If caller is not the admin multisig


```solidity
function removeUserRole(address user, uint8 role) public virtual requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to remove the role from|
|`role`|`uint8`|The role to remove|


### getAllRoles

Returns all roles for a user


```solidity
function getAllRoles(address user) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to get the roles for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|A bitmask of all roles for the user|


### setRoleRemovable

Sets a role as removable or not

*This function can only be called by the owner (timelock)*

**Note:**
reverts: If caller is not the owner


```solidity
function setRoleRemovable(uint8 role, bool allowed) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`uint8`|The role to set as removable|
|`allowed`|`bool`|Whether the role should be removable|


## Events
### RemovableRoleConfigured
Emitted when a role is configured as removable


```solidity
event RemovableRoleConfigured(uint8 indexed role, bool allowed);
```

## Errors
### RoleRemovalNotAllowed
The error emitted when a user attempts to remove a role


```solidity
error RoleRemovalNotAllowed();
```

