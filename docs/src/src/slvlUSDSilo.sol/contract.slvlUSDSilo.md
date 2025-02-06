# slvlUSDSilo
[Git Source](https://github.com/Level-Money/contracts/blob/7fc97def4c32b2c55e844838ecbb532dceb8179d/src/slvlUSDSilo.sol)

**Inherits:**
[IslvlUSDSiloDefinitions](/src/interfaces/IslvlUSDSiloDefinitions.sol/interface.IslvlUSDSiloDefinitions.md)

The Silo allows to store lvlUSD during the stake cooldown process.
Forked from Ethena's USDeSilo contract.


## State Variables
### _STAKING_VAULT

```solidity
address immutable _STAKING_VAULT;
```


### _lvlUSD

```solidity
IERC20 immutable _lvlUSD;
```


## Functions
### constructor


```solidity
constructor(address stakingVault, address lvlUSD);
```

### onlyStakingVault


```solidity
modifier onlyStakingVault();
```

### withdraw


```solidity
function withdraw(address to, uint256 amount) external onlyStakingVault;
```

