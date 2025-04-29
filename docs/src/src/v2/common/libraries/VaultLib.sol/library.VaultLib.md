# VaultLib
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/common/libraries/VaultLib.sol)

**Author:**
Level (https://level.money)

Library to manage vault operations, such as depositing into and withdrawing from strategies


## State Variables
### AAVE_V3_POOL_ADDRESSES_PROVIDER

```solidity
address public constant AAVE_V3_POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
```


## Functions
### _getTotalAssets

Returns the total assets of the given strategies


```solidity
function _getTotalAssets(BoringVault vault, StrategyConfig[] memory strategies, address asset)
    internal
    view
    returns (uint256 total);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`strategies`|`StrategyConfig[]`|The strategy configs|
|`asset`|`address`|The asset address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`total`|`uint256`|The total assets of the given strategies, denominated in the common base collateral|


### _withdrawBatch

Withdraws assets from the given strategies

*Assumes that all strategies share the same `baseCollateral`*


```solidity
function _withdrawBatch(BoringVault vault, StrategyConfig[] memory strategies, uint256 amount)
    internal
    returns (uint256 withdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`strategies`|`StrategyConfig[]`|The strategy configs|
|`amount`|`uint256`|The amount of assets to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawn`|`uint256`|The amount of assets withdrawn, using the common baseCollateral's decimals|


### _deposit

Deposits assets into the given strategy


```solidity
function _deposit(BoringVault vault, StrategyConfig memory config, uint256 amount)
    internal
    returns (uint256 deposited);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`config`|`StrategyConfig`|The strategy config|
|`amount`|`uint256`|The amount of assets to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deposited`|`uint256`|The amount of assets deposited|


### _withdraw

Withdraws assets from the given strategy


```solidity
function _withdraw(BoringVault vault, StrategyConfig memory config, uint256 amount)
    internal
    returns (uint256 withdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`config`|`StrategyConfig`|The strategy config|
|`amount`|`uint256`|The amount of assets to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawn`|`uint256`|The amount of assets withdrawn|


### _depositToAave

Deposits assets into Aave v3

*aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.*


```solidity
function _depositToAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 deposited);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`_config`|`StrategyConfig`|The strategy config|
|`amount`|`uint256`|The amount of assets to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deposited`|`uint256`|The amount of assets deposited|


### _withdrawFromAave

Withdraws assets from Aave v3

*aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.*


```solidity
function _withdrawFromAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 withdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`_config`|`StrategyConfig`|The strategy config|
|`amount`|`uint256`|The amount of assets to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawn`|`uint256`|The amount of assets withdrawn|


### _getAaveV3Pool

Returns the Aave v3 pool address


```solidity
function _getAaveV3Pool() internal view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|pool_ The Aave v3 pool address|


### _depositToMorpho

Deposits assets into Morpho


```solidity
function _depositToMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 deposited);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`_config`|`StrategyConfig`|The strategy config|
|`amount`|`uint256`|The amount of assets to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deposited`|`uint256`|The amount of assets deposited|


### _withdrawFromMorpho

Withdraws assets from Morpho


```solidity
function _withdrawFromMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 withdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`BoringVault`|The vault address|
|`_config`|`StrategyConfig`|The strategy config|
|`amount`|`uint256`|The amount of assets to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawn`|`uint256`|The amount of assets withdrawn|


## Events
### DepositToAave
Emitted when assets are deposited into Aave v3


```solidity
event DepositToAave(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`address`|The vault address|
|`asset`|`address`|The asset address|
|`amountDeposited`|`uint256`|The amount of assets deposited|
|`sharesReceived`|`uint256`|The amount of shares received|

### WithdrawFromAave
Emitted when assets are withdrawn from Aave v3


```solidity
event WithdrawFromAave(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`address`|The vault address|
|`asset`|`address`|The asset address|
|`amountWithdrawn`|`uint256`|The amount of assets withdrawn|
|`sharesSent`|`uint256`|The amount of shares sent|

### DepositToMorpho
Emitted when assets are deposited into Morpho


```solidity
event DepositToMorpho(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`address`|The vault address|
|`asset`|`address`|The asset address|
|`amountDeposited`|`uint256`|The amount of assets deposited|
|`sharesReceived`|`uint256`|The amount of shares received|

### WithdrawFromMorpho
Emitted when assets are withdrawn from Morpho


```solidity
event WithdrawFromMorpho(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`address`|The vault address|
|`asset`|`address`|The asset address|
|`amountWithdrawn`|`uint256`|The amount of assets withdrawn|
|`sharesSent`|`uint256`|The amount of shares sent|

