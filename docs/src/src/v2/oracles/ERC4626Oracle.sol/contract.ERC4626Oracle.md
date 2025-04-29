# ERC4626Oracle
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/oracles/ERC4626Oracle.sol)

**Inherits:**
[IERC4626Oracle](/src/v2/interfaces/level/IERC4626Oracle.sol/interface.IERC4626Oracle.md)

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

Oracle contract for ERC4626 vaults. Returns the current `convertToAssets` value of a vault share


## State Variables
### vault

```solidity
IERC4626 public immutable vault;
```


### decimals_

```solidity
uint8 public immutable decimals_;
```


### oneShare

```solidity
uint256 public immutable oneShare;
```


## Functions
### constructor


```solidity
constructor(IERC4626 _vault);
```

### update


```solidity
function update() external;
```

### decimals


```solidity
function decimals() external view returns (uint8);
```

### description


```solidity
function description() external pure returns (string memory);
```

### version


```solidity
function version() external pure returns (uint256);
```

### getRoundData


```solidity
function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80);
```

### latestRoundData


```solidity
function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
```

