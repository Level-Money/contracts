# KarakReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/reserve/LevelKarakReserveManager.sol)

**Inherits:**
[LevelBaseReserveManager](/src/reserve/LevelBaseReserveManager.sol/abstract.LevelBaseReserveManager.md), [IKarakReserveManager](/src/interfaces/ILevelKarakReserveManager.sol/interface.IKarakReserveManager.md)

This contract stores and manages reserves from minted lvlUSD


## Functions
### constructor


```solidity
constructor(IlvlUSD _lvlusd, IStakedlvlUSD _stakedlvlUSD, address _admin, address _allowlister)
    LevelBaseReserveManager(_lvlusd, _stakedlvlUSD, _admin, _allowlister);
```

### depositToKarak


```solidity
function depositToKarak(address vault, uint256 amount) external onlyRole(MANAGER_AGENT_ROLE) returns (uint256 shares);
```

### startRedeemFromKarak


```solidity
function startRedeemFromKarak(address vault, uint256 shares)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused
    returns (bytes32 withdrawalKey);
```

### finishRedeemFromKarak


```solidity
function finishRedeemFromKarak(address vault, bytes32 withdrawalKey)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused;
```

