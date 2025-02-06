# BaseYieldManager
[Git Source](https://github.com/Level-Money/contracts/blob/7fc97def4c32b2c55e844838ecbb532dceb8179d/src/yield/BaseYieldManager.sol)

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

