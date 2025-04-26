# SymbioticReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v1/reserve/LevelSymbioticReserveManager.sol)

**Inherits:**
[LevelBaseReserveManager](/src/v1/reserve/LevelBaseReserveManager.sol/abstract.LevelBaseReserveManager.md), [ISymbioticReserveManager](/src/v1/interfaces/ILevelSymbioticReserveManager.sol/interface.ISymbioticReserveManager.md)

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

