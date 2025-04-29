# VaultManagerStorage
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/usd/VaultManagerStorage.sol)

**Inherits:**
[IVaultManager](/src/v2/interfaces/level/IVaultManager.sol/interface.IVaultManager.md)

**Author:**
Level (https://level.money)

.-==+=======+:
:---=-::-==:
.-:-==-:-==:
.:::--::::::.     .--:-=--:--.       .:--:::--..
.=++=++:::::..     .:::---::--.    ....::...:::.
:::-::..::..      .::::-:::::.     ...::...:::.
...::..::::..     .::::--::-:.    ....::...:::..
............      ....:::..::.    ------:......
...........     ........:....     .....::..:..    ======-......      ...........
:------:.:...   ...:+***++*#+     .------:---.    ...::::.:::...   .....:-----::.
.::::::::-:..   .::--..:-::..    .-=+===++=-==:   ...:::..:--:..   .:==+=++++++*:

Storage contract for the VaultManager


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


