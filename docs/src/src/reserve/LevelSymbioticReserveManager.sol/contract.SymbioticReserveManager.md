# SymbioticReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/7fc97def4c32b2c55e844838ecbb532dceb8179d/src/reserve/LevelSymbioticReserveManager.sol)

**Inherits:**
[LevelBaseReserveManager](/src/reserve/LevelBaseReserveManager.sol/abstract.LevelBaseReserveManager.md), [ISymbioticReserveManager](/src/interfaces/ILevelSymbioticReserveManager.sol/interface.ISymbioticReserveManager.md)

This contract stores and manages reserves to be deployed to Symbiotic.


## Functions
### constructor


```solidity
constructor(IlvlUSD _lvlusd, IStakedlvlUSD _stakedlvlUSD, address _admin, address _allowlister)
    LevelBaseReserveManager(_lvlusd, _stakedlvlUSD, _admin, _allowlister);
```

### depositToSymbiotic


```solidity
function depositToSymbiotic(address vault, uint256 amount)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused
    returns (uint256 depositedAmount, uint256 mintedShares);
```

### withdrawFromSymbiotic


```solidity
function withdrawFromSymbiotic(address vault, uint256 amount)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused
    returns (uint256 burnedShares, uint256 mintedShares);
```

### claimFromSymbiotic


```solidity
function claimFromSymbiotic(address vault, uint256 epoch)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused
    returns (uint256 amount);
```

