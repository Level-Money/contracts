# VaultManagerStorage
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/usd/VaultManagerStorage.sol)

**Inherits:**
[IVaultManager](/src/v2/interfaces/level/IVaultManager.sol/interface.IVaultManager.md)


## State Variables
### vault

```solidity
BoringVault public vault;
```


### defaultStrategies

```solidity
mapping(address => address[]) public defaultStrategies;
```


### assetToStrategy

```solidity
mapping(address => mapping(address => StrategyConfig)) public assetToStrategy;
```


### receiptTokenToAsset

```solidity
mapping(address => address) public receiptTokenToAsset;
```


### __gap
*This empty reserved space is put in place to allow future versions to add new
variables without shifting down storage in the inheritance chain.
See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps*


```solidity
uint256[50] private __gap;
```


## Functions
### constructor


```solidity
constructor(address vault_);
```

