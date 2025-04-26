# slvlUSDSilo
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/slvlUSDSilo.sol)

**Inherits:**
[IslvlUSDSiloDefinitions](/src/v1/interfaces/IslvlUSDSiloDefinitions.sol/interface.IslvlUSDSiloDefinitions.md)

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

