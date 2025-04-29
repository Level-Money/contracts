# Silo
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/usd/Silo.sol)

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

Contract for storing assets during cooldown for LevelMintingV2

*Callable by LevelMintingV2, which is the deployer*


## State Variables
### owner

```solidity
address public immutable owner;
```


## Functions
### constructor


```solidity
constructor(address _owner);
```

### withdraw

only callable by LevelMintingV2


```solidity
function withdraw(address beneficiary, address asset, uint256 amount) external;
```

