# IMetaMorphoStaticTyping
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/interfaces/morpho/IMetaMorpho.sol)

**Inherits:**
[IMetaMorphoBase](/src/v2/interfaces/morpho/IMetaMorpho.sol/interface.IMetaMorphoBase.md)

*This interface is inherited by MetaMorpho so that function signatures are checked by the compiler.*

*Consider using the IMetaMorpho interface instead of this one.*


## Functions
### config

Returns the current configuration of each market.


```solidity
function config(Id) external view returns (uint184 cap, bool enabled, uint64 removableAt);
```

### pendingGuardian

Returns the pending guardian.


```solidity
function pendingGuardian() external view returns (address guardian, uint64 validAt);
```

### pendingCap

Returns the pending cap for each market.


```solidity
function pendingCap(Id) external view returns (uint192 value, uint64 validAt);
```

### pendingTimelock

Returns the pending timelock.


```solidity
function pendingTimelock() external view returns (uint192 value, uint64 validAt);
```

