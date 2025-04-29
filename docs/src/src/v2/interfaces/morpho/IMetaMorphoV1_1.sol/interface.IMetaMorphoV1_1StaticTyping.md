# IMetaMorphoV1_1StaticTyping
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/interfaces/morpho/IMetaMorphoV1_1.sol)

**Inherits:**
[IMetaMorphoV1_1Base](/src/v2/interfaces/morpho/IMetaMorphoV1_1.sol/interface.IMetaMorphoV1_1Base.md)

*This interface is inherited by MetaMorphoV1_1 so that function signatures are checked by the compiler.*

*Consider using the IMetaMorphoV1_1 interface instead of this one.*


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

