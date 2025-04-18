# IVaultManager
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/level/IVaultManager.sol)

**Inherits:**
[IVaultManagerEvents](/src/v2/interfaces/level/IVaultManager.sol/interface.IVaultManagerEvents.md), [IVaultManagerErrors](/src/v2/interfaces/level/IVaultManager.sol/interface.IVaultManagerErrors.md)

Interface for managing vault operations and strategies

*Inherits error and event interfaces from IVaultManagerEvents and IVaultManagerErrors*


## Functions
### initialize

Initializes the contract with admin and guard addresses


```solidity
function initialize(address admin_, address guard_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin_`|`address`|Address of the admin who will have administrative privileges|
|`guard_`|`address`|Address of the guard that provides security controls|


### setVault

Sets the vault address

*Restricted to admin timelock*


```solidity
function setVault(address vault_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault_`|`address`|The address of the vault to be set|


### addAssetStrategy

Adds a new strategy for a specific asset with configuration

*Restricted to admin timelock*


```solidity
function addAssetStrategy(address asset, address strategy, StrategyConfig calldata config) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategy`|`address`|The address of the strategy to add|
|`config`|`StrategyConfig`|Configuration parameters for the strategy|


### removeAssetStrategy

Removes a strategy for a specific asset

*Restricted to admin timelock*


```solidity
function removeAssetStrategy(address asset, address strategy) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategy`|`address`|The address of the strategy to remove|


### getUnderlyingAssetFor

Returns the underlying asset address for a given receipt token


```solidity
function getUnderlyingAssetFor(address receiptToken) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiptToken`|`address`|The address of the receipt token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the underlying asset|


### getDefaultStrategies

Gets the list of default strategies for a specific asset


```solidity
function getDefaultStrategies(address asset) external view returns (address[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|An array of strategy addresses that are set as default for the asset|


### setDefaultStrategies

Sets the default strategies for a specific asset

*Restricted to admin timelock*


```solidity
function setDefaultStrategies(address asset, address[] calldata strategies) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategies`|`address[]`|Array of strategy addresses to set as default|


### deposit

Deposits an amount of an asset to a specific strategy

*Callable by STRATEGIST_ROLE*


```solidity
function deposit(address asset, address strategy, uint256 amount) external returns (uint256 deposited);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to deposit|
|`strategy`|`address`|The address of the strategy to deposit into|
|`amount`|`uint256`|The amount of the asset to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deposited`|`uint256`|The actual amount deposited|


### withdraw

Withdraws an amount of an asset from a specific strategy

*Callable by STRATEGIST_ROLE*


```solidity
function withdraw(address asset, address strategy, uint256 amount) external returns (uint256 withdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to withdraw|
|`strategy`|`address`|The address of the strategy to withdraw from|
|`amount`|`uint256`|The amount of the asset to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawn`|`uint256`|The actual amount withdrawn|


### depositDefault

Deposits an amount of an asset to the default strategies

*Callable by STRATEGIST_ROLE*


```solidity
function depositDefault(address asset, uint256 amount) external returns (uint256 deposited);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to deposit|
|`amount`|`uint256`|The amount of the asset to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deposited`|`uint256`|The actual amount deposited|


### withdrawDefault

Withdraws an amount of an asset from the default strategies

*Callable by STRATEGIST_ROLE*


```solidity
function withdrawDefault(address asset, uint256 amount) external returns (uint256 withdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to withdraw|
|`amount`|`uint256`|The amount of the asset to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawn`|`uint256`|The actual amount withdrawn|


