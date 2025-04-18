# IMetaMorpho
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v2/interfaces/morpho/IMetaMorpho.sol)

**Inherits:**
[IMetaMorphoBase](/src/v2/interfaces/morpho/IMetaMorpho.sol/interface.IMetaMorphoBase.md), IERC4626, IERC20Permit, [IOwnable](/src/v2/interfaces/morpho/IMetaMorpho.sol/interface.IOwnable.md), [IMulticall](/src/v2/interfaces/morpho/IMetaMorpho.sol/interface.IMulticall.md)

**Author:**
Morpho Labs

*Use this interface for MetaMorpho to have access to all the functions with the appropriate function signatures.*

**Note:**
contact: security@morpho.org


## Functions
### config

Returns the current configuration of each market.


```solidity
function config(Id) external view returns (MarketConfig memory);
```

### pendingGuardian

Returns the pending guardian.


```solidity
function pendingGuardian() external view returns (PendingAddress memory);
```

### pendingCap

Returns the pending cap for each market.


```solidity
function pendingCap(Id) external view returns (PendingUint192 memory);
```

### pendingTimelock

Returns the pending timelock.


```solidity
function pendingTimelock() external view returns (PendingUint192 memory);
```

