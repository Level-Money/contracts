# ISingleAdminAccessControl
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v1/interfaces/ISingleAdminAccessControl.sol)


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

