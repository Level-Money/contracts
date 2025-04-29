# RewardsManagerStorage
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/usd/RewardsManagerStorage.sol)

**Inherits:**
[IRewardsManager](/src/v2/interfaces/level/IRewardsManager.sol/interface.IRewardsManager.md)

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

Storage contract for RewardsManager. Separate to make it easier to discern upgrades.

*Inherits interface from IRewardsManager*


## State Variables
### vault

```solidity
BoringVault public vault;
```


### treasury

```solidity
address public treasury;
```


### allStrategies

```solidity
mapping(address => StrategyConfig[]) public allStrategies;
```


### oracles

```solidity
mapping(address => address) public oracles;
```


### allBaseCollateral

```solidity
address[] public allBaseCollateral;
```


### HEARTBEAT

```solidity
uint256 public constant HEARTBEAT = 1 days;
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
constructor();
```

