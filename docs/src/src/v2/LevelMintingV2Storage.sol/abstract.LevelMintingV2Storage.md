# LevelMintingV2Storage
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/LevelMintingV2Storage.sol)

**Inherits:**
[ILevelMintingV2](/src/v2/interfaces/level/ILevelMintingV2.sol/interface.ILevelMintingV2.md)

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

Storage contract for the LevelMintingV2


## State Variables
### vaultManager

```solidity
VaultManager public vaultManager;
```


### silo

```solidity
Silo public silo;
```


### mintableAssets

```solidity
mapping(address => bool) public mintableAssets;
```


### redeemableAssets

```solidity
mapping(address => bool) public redeemableAssets;
```


### userCooldown

```solidity
mapping(address user => mapping(address asset => uint256 cooldown)) public userCooldown;
```


### cooldownDuration

```solidity
uint256 public cooldownDuration;
```


### mintedPerBlock
lvlUSD minted per block


```solidity
mapping(uint256 => uint256) public mintedPerBlock;
```


### redeemedPerBlock
asset redeemed per block


```solidity
mapping(uint256 => uint256) public redeemedPerBlock;
```


### maxMintPerBlock
max minted lvlUSD allowed per block


```solidity
uint256 public maxMintPerBlock;
```


### maxRedeemPerBlock
max redeemed collateral allowed per block


```solidity
uint256 public maxRedeemPerBlock;
```


### pendingRedemption

```solidity
mapping(address => mapping(address => uint256)) public pendingRedemption;
```


### oracles

```solidity
mapping(address => address) public oracles;
```


### heartbeats

```solidity
mapping(address => uint256) public heartbeats;
```


### isLevelOracle

```solidity
mapping(address => bool) public isLevelOracle;
```


### lvlusd
lvlusd stablecoin


```solidity
IlvlUSD public constant lvlusd = IlvlUSD(0x7C1156E515aA1A2E851674120074968C905aAF37);
```


### LVLUSD_DECIMAL

```solidity
uint8 public constant LVLUSD_DECIMAL = 18;
```


### isBaseCollateral

```solidity
mapping(address => bool) public isBaseCollateral;
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

