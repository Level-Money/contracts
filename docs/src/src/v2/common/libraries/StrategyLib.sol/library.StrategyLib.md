# StrategyLib
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/common/libraries/StrategyLib.sol)

**Author:**
Level (https://level.money)

Library to get values stored in strategies


## Functions
### getAssets

Returns the total assets of the given strategies


```solidity
function getAssets(StrategyConfig[] memory configs, address vault) internal view returns (uint256 assets_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`configs`|`StrategyConfig[]`|The strategy configs. Reverts if the strategies have different base collateral|
|`vault`|`address`|The vault address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets_`|`uint256`|The total assets of the given strategies, denominated in the common base collateral|


### getAssets

Returns the total assets of the given strategy


```solidity
function getAssets(StrategyConfig memory config, address vault) internal view returns (uint256 assets_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`config`|`StrategyConfig`|The strategy config|
|`vault`|`address`|The vault address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets_`|`uint256`|The total assets of the given strategy, denominated in the strategy's base collateral|


### validateStrategy

Validate a strategy configuration

*Reverts with InvalidStrategy if the strategy is invalid*


```solidity
function validateStrategy(StrategyConfig memory config, address baseCollateral) internal pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`config`|`StrategyConfig`|The strategy configuration to validate|
|`baseCollateral`|`address`|The base collateral of the strategy|


## Errors
### InvalidStrategy
Error thrown when a strategy is invalid


```solidity
error InvalidStrategy();
```

