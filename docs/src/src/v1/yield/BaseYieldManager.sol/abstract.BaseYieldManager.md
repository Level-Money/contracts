# BaseYieldManager
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v1/yield/BaseYieldManager.sol)

**Inherits:**
[ILevelBaseYieldManager](/src/v1/interfaces/ILevelBaseYieldManager.sol/interface.ILevelBaseYieldManager.md), [SingleAdminAccessControl](/src/v1/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md)


## State Variables
### YIELD_RECOVERER_ROLE

```solidity
bytes32 public YIELD_RECOVERER_ROLE = keccak256("YIELD_RECOVERER_ROLE");
```


## Functions
### constructor


```solidity
constructor(address _admin);
```

### approveSpender


```solidity
function approveSpender(address token, address spender, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE);
```

