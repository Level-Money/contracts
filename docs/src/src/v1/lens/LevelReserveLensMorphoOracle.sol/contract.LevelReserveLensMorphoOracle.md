# LevelReserveLensMorphoOracle
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/lens/LevelReserveLensMorphoOracle.sol)

**Inherits:**
[ILevelReserveLensMorphoOracle](/src/v1/interfaces/lens/ILevelReserveLensMorphoOracle.sol/interface.ILevelReserveLensMorphoOracle.md), [SingleAdminAccessControl](/src/v1/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md), Pausable

**Author:**
Level (https://level.money)

.-==+=======+:
:---=-::-==:g
.-:-==-:-==:
.:::--::::::.     .--:-=--:--.       .:--:::--..
.=++=++:::::..     .:::---::--.    ....::...:::.
:::-::..::..      .::::-:::::.     ...::...:::.
...::..::::..     .::::--::-:.    ....::...:::..
............      ....:::..::.    ------:......
...........     ........:....     .....::..:..    ======-......      ...........
:------:.:...   ...:+***++*#+     .------:---.    ...::::.:::...   .....:-----::.
.::::::::-:..   .::--..:-::..    .-=+===++=-==:   ...:::..:--:..   .:==+=++++++*:

The LevelReserveLensMorphoOracle contract is a thin wrapper around LevelReserveLens that implements the Chainlink AggregatorV3Interface.

This contract reverts to a default price of $1 to protect borrowers from liquidation, which may come at the cost of lenders. Vault curators and lenders should take care to monitor the solvency of lvlUSD off-chain and pause new loans if necessary. See audit reports for more details.


## State Variables
### PAUSER_ROLE

```solidity
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
```


### lens

```solidity
ILevelReserveLens public immutable lens;
```


## Functions
### constructor


```solidity
constructor(address _admin, address _pauser, address _lens);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_admin`|`address`|The address of the admin.|
|`_pauser`|`address`|The address of the pauser.|
|`_lens`|`address`|The address of the LevelReserveLens contract.|


### decimals

*Returns the number of decimals; use Chainlink's default for USD pairs.*


```solidity
function decimals() public pure override returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|decimals The number of decimals.|


### description

*Returns a short description of the aggregator.*


```solidity
function description() external pure override returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|description A description of the aggregator.|


### version

*Returns the version of the interface; hard-coded to 0.*


```solidity
function version() external pure override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|version The version of the interface.|


### setPaused

Sets the paused state of the contract


```solidity
function setPaused(bool _paused) external onlyRole(PAUSER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_paused`|`bool`|True to pause, false to unpause|


### defaultRoundData

*Returns a default price of $1 (1e18). Intended to be used when the oracle cannot fetch the price from the lens contract, or if the contract is paused.*


```solidity
function defaultRoundData()
    public
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```

### getRoundData

*Returns the latest round data (since this oracle does not require data to be pushed). See latestRoundData for more details.*


```solidity
function getRoundData(uint80)
    external
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```

### latestRoundData

*Returns the price of lvlUSD. This function should always return some value.*

*Invariants: answer > 0, answer <= this.decimals()*


```solidity
function latestRoundData()
    external
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`roundId`|`uint80`|non-meaningful value|
|`answer`|`int256`|The price of lvlUSD, where 1e18 means 1 USD. Returns $1 (1e18) if the reserves are overcollateralized, if the contract is paused, or the underlying lens contract reverts. Otherwise, returns the ratio of USD reserves to lvlUSD supply.|
|`startedAt`|`uint256`|non-meaningful value|
|`updatedAt`|`uint256`|the timestamp of the current block|
|`answeredInRound`|`uint80`|non-meaningful value|


