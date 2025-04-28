# ILevelReserveLensMorphoOracle
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/interfaces/lens/ILevelReserveLensMorphoOracle.sol)

**Inherits:**
[AggregatorV3Interface](/src/v1/interfaces/AggregatorV3Interface.sol/interface.AggregatorV3Interface.md)

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

Interface for a Chainlink-compatible oracle wrapper around LevelReserveLens that provides lvlUSD price data


## Functions
### setPaused

Sets the paused state of the contract


```solidity
function setPaused(bool _paused) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_paused`|`bool`|True to pause, false to unpause|


### defaultRoundData

Returns a default price of $1

*Intended to be used when the oracle cannot fetch the price from the lens contract, or if the contract is paused*


```solidity
function defaultRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`roundId`|`uint80`|non-meaningful value|
|`answer`|`int256`|The default price (1 USD)|
|`startedAt`|`uint256`|The current block timestamp|
|`updatedAt`|`uint256`|The current block timestamp|
|`answeredInRound`|`uint80`|non-meaningful value|


