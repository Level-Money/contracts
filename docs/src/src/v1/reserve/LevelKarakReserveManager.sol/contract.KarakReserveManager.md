# KarakReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v1/reserve/LevelKarakReserveManager.sol)

**Inherits:**
[LevelBaseReserveManager](/src/v1/reserve/LevelBaseReserveManager.sol/abstract.LevelBaseReserveManager.md), [IKarakReserveManager](/src/v1/interfaces/ILevelKarakReserveManager.sol/interface.IKarakReserveManager.md)

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

