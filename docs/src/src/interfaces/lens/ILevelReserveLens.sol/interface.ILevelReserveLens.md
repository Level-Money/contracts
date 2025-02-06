# ILevelReserveLens
[Git Source](https://github.com/Level-Money/contracts/blob/7fc97def4c32b2c55e844838ecbb532dceb8179d/src/interfaces/lens/ILevelReserveLens.sol)

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

Interface for querying the reserves backing lvlUSD per underlying collateral token address.


## Functions
### getReserves

Returns the reserves of the given token, including any lending derivatives. For example, if the token is USDC, we will return the balance of all ReserveManagers' USDC and wrapped Aave tokens. Also includes reserves in LevelMinting.

*Note: waUSDC/T and USDC/T are used interchangeably because the wrapped Aave tokens are withdrawable 1:1 for the underlying token*

*Note: the reserves returned may include deposits from non-Level participants, which may cause the total reserves to be higher than expected. This should not affect the lvlUSD/USD price (which is capped at 1 if the reserves are overcollateralized).*


```solidity
function getReserves(address collateral) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The reserves of the given token, in lvlUSD's decimals (18)|


### getReserveValue

Returns the USD-value reserves of the given token. See getReserves for more details.


```solidity
function getReserveValue(address collateral) external view returns (uint256 usdReserves);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`usdReserves`|`uint256`|The USD-value reserves of the given token, in lvlUSD's decimals (18)|


### getReserveValue

Returns the total dollar value of reserves backing lvlUSD, including all collateral tokens.


```solidity
function getReserveValue() external view returns (uint256 usdReserves);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`usdReserves`|`uint256`|The total dollar value of reserves backing lvlUSD, in lvlUSD's decimals|


### getReservePrice

Returns the reserve price of lvlUSD. If the reserves are overcollateralized, return $1 (1e18). Otherwise, return the ratio of USD reserves to lvlUSD supply.


```solidity
function getReservePrice() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|reservePrice The reserve price of lvlUSD, with lvlUSD's decimals (18).|


### getMintPrice

Returns the price of minting lvlUSD using the same logic as LevelMinting


```solidity
function getMintPrice(IERC20Metadata collateral) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|mintPrice The price of lvlUSD for 1 unit of the collateral token, with lvlUSD's decimals (18)|


### getRedeemPrice

Returns the price of redeeming lvlUSD using the same logic as LevelMinting


```solidity
function getRedeemPrice(IERC20Metadata collateral) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|redeemPrice The price of collateral for 1 unit of lvlUSD, with the same decimals as the collateral token|


### getEigenStake

Returns the underlying tokens staked in a given Eigen strategy

*Note: this function returns everything held in the strategy, which may include deposits from non-Level participants*


```solidity
function getEigenStake(IERC20Metadata collateral, address strategy) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token|
|`strategy`|`address`|The address of the strategy|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|eigenStake The total collateral tokens held by the given Level strategy|


### getSymbioticStake

Returns the underlying tokens staked in a given Symbiotic vault and burner

*Note: this function returns everything held in the strategy, which may include deposits from non-Level participants*


```solidity
function getSymbioticStake(IERC20Metadata collateral, address vault) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token|
|`vault`|`address`|The address of the Symbiotic vault|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|symbioticStake The total collateral tokens held by the given vault and vault burner|


### safeAdjustForDecimals

Adjusts the amount for the difference in decimals. Reverts if the amount would lose precision.


```solidity
function safeAdjustForDecimals(uint256 amount, uint8 fromDecimals, uint8 toDecimals) external pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to adjust|
|`fromDecimals`|`uint8`|The decimals of the amount|
|`toDecimals`|`uint8`|The decimals to adjust to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|adjustedAmount The adjusted amount|


