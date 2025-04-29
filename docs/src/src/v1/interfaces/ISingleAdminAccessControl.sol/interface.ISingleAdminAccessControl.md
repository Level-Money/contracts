# ISingleAdminAccessControl
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v1/interfaces/ISingleAdminAccessControl.sol)


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

