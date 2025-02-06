# SingleAdminAccessControl
[Git Source](https://github.com/Level-Money/contracts/blob/7fc97def4c32b2c55e844838ecbb532dceb8179d/src/auth/v4/SingleAdminAccessControl.sol)

**Inherits:**
IERC5313, [ISingleAdminAccessControl](/src/interfaces/ISingleAdminAccessControl.sol/interface.ISingleAdminAccessControl.md), AccessControl

SingleAdminAccessControl is a contract that provides a single admin role

This contract is a simplified alternative to OpenZeppelin's AccessControlDefaultAdminRules

*Changelog: update solidity versions*


## State Variables
### _currentDefaultAdmin

```solidity
address private _currentDefaultAdmin;
```


### _pendingDefaultAdmin

```solidity
address private _pendingDefaultAdmin;
```


## Functions
### notAdmin


```solidity
modifier notAdmin(bytes32 role);
```

### transferAdmin

Transfer the admin role to a new address

This can ONLY be executed by the current admin


```solidity
function transferAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newAdmin`|`address`|address|


### acceptAdmin


```solidity
function acceptAdmin() external;
```

### grantRole

grant a role

can only be executed by the current single admin

admin role cannot be granted externally


```solidity
function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) notAdmin(role);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`bytes32`|bytes32|
|`account`|`address`|address|


### revokeRole

revoke a role

can only be executed by the current admin

admin role cannot be revoked


```solidity
function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) notAdmin(role);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`bytes32`|bytes32|
|`account`|`address`|address|


### renounceRole

renounce the role of msg.sender

admin role cannot be renounced


```solidity
function renounceRole(bytes32 role, address account) public virtual override notAdmin(role);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`bytes32`|bytes32|
|`account`|`address`|address|


### owner

*See [IERC5313-owner](/src/interfaces/IKarakVault.sol/interface.IVault.md#owner).*


```solidity
function owner() public view virtual returns (address);
```

### _grantRole

no way to change admin without removing old admin first


```solidity
function _grantRole(bytes32 role, address account) internal override;
```

