# SingleAdminAccessControl
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v1/auth/v5/SingleAdminAccessControl.sol)

**Inherits:**
IERC5313, [ISingleAdminAccessControl](/src/v1/interfaces/ISingleAdminAccessControl.sol/interface.ISingleAdminAccessControl.md), AccessControl

SingleAdminAccessControl is a contract that provides a single admin role with timelock

This contract is a simplified alternative to OpenZeppelin's AccessControlDefaultAdminRules

*Added 3-day timelock for admin transfers*


## State Variables
### _currentDefaultAdmin

```solidity
address private _currentDefaultAdmin;
```


### _pendingDefaultAdmin

```solidity
address private _pendingDefaultAdmin;
```


### TIMELOCK_DELAY

```solidity
uint256 public constant TIMELOCK_DELAY = 3 days;
```


### _transferRequestTime

```solidity
uint256 private _transferRequestTime;
```


## Functions
### notAdmin


```solidity
modifier notAdmin(bytes32 role);
```

### transferAdmin

Transfer the admin role to a new address

This can ONLY be executed by the current admin

Initiates a transfer request with a 3-day timelock


```solidity
function transferAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newAdmin`|`address`|address of the new admin|


### cancelTransferAdmin

Cancel a pending admin transfer request

Can only be called by the current admin


```solidity
function cancelTransferAdmin() external onlyRole(DEFAULT_ADMIN_ROLE);
```

### acceptAdmin

Accept the admin role transfer after timelock expires

Can only be called by the pending admin after the timelock period


```solidity
function acceptAdmin() external;
```

### getTransferTimelockStatus

Check the remaining time until a transfer can be accepted


```solidity
function getTransferTimelockStatus() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|remaining time in seconds, 0 if no active transfer or if timelock has expired|


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

*See [IERC5313-owner](/src/v1/auth/v4/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md#owner).*


```solidity
function owner() public view virtual returns (address);
```

### _grantRole

no way to change admin without removing old admin first


```solidity
function _grantRole(bytes32 role, address account) internal override returns (bool);
```

## Events
### AdminTransferCancelled

```solidity
event AdminTransferCancelled(address indexed currentAdmin, address indexed pendingAdmin);
```

## Errors
### TimelockNotExpired

```solidity
error TimelockNotExpired(uint256 remainingTime);
```

### NoActiveTransferRequest

```solidity
error NoActiveTransferRequest();
```

### TransferAlreadyInProgress

```solidity
error TransferAlreadyInProgress();
```

