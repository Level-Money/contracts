# ISingleAdminAccessControl
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/interfaces/ISingleAdminAccessControl.sol)


## Events
### AdminTransferred

```solidity
event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
```

### AdminTransferRequested

```solidity
event AdminTransferRequested(address indexed oldAdmin, address indexed newAdmin);
```

## Errors
### InvalidAdminChange

```solidity
error InvalidAdminChange();
```

### NotPendingAdmin

```solidity
error NotPendingAdmin();
```

