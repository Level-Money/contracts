# ERC4626OracleFactory
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/oracles/ERC4626OracleFactory.sol)

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

Factory contract for ERC4626 Oracle and ERC4626 Delayed Oracle


## Functions
### create


```solidity
function create(IERC4626 vault) external returns (ERC4626Oracle);
```

### createDelayed


```solidity
function createDelayed(IERC4626 vault, uint256 delay) external returns (ERC4626DelayedOracle);
```

