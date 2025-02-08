# BaseYieldManager
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/yield/BaseYieldManager.sol)

**Inherits:**
[ILevelBaseYieldManager](/src/interfaces/ILevelBaseYieldManager.sol/interface.ILevelBaseYieldManager.md), [SingleAdminAccessControl](/src/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md)


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

