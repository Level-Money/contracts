# ISingleAdminAccessControl
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/interfaces/ISingleAdminAccessControl.sol)


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

