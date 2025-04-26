# ISingleAdminAccessControl
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v1/interfaces/ISingleAdminAccessControl.sol)


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

