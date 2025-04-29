# VaultManager
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/usd/VaultManager.sol)

**Inherits:**
[VaultManagerStorage](/src/v2/usd/VaultManagerStorage.sol/abstract.VaultManagerStorage.md), Initializable, UUPSUpgradeable, [AuthUpgradeable](/src/v2/auth/AuthUpgradeable.sol/abstract.AuthUpgradeable.md), [PauserGuardedUpgradable](/src/v2/common/guard/PauserGuardedUpgradable.sol/abstract.PauserGuardedUpgradable.md)

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

Contract for depositing and withdrawing into BoringVault


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(address admin_, address guard_, address vault_) external initializer;
```

### deposit

Deposits an amount of an asset to a specific strategy

*Callable by STRATEGIST_ROLE*


```solidity
function deposit(address asset, address strategy, uint256 amount)
    external
    requiresAuth
    notPaused
    returns (uint256 deposited);
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
function withdraw(address asset, address strategy, uint256 amount)
    external
    requiresAuth
    notPaused
    returns (uint256 withdrawn);
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
function depositDefault(address asset, uint256 amount) external requiresAuth notPaused returns (uint256 deposited);
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
function withdrawDefault(address asset, uint256 amount) external requiresAuth notPaused returns (uint256 withdrawn);
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


### setGuard


```solidity
function setGuard(address _guard) external requiresAuth;
```

### setVault

Sets the vault address

*Restricted to admin timelock*


```solidity
function setVault(address _vault) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vault`|`address`||


### addAssetStrategy

Adds a new strategy for a specific asset with configuration

*Restricted to admin timelock*


```solidity
function addAssetStrategy(address _asset, address _strategy, StrategyConfig calldata _config) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_asset`|`address`||
|`_strategy`|`address`||
|`_config`|`StrategyConfig`||


### removeAssetStrategy

Removes a strategy for a specific asset

*Restricted to admin timelock*


```solidity
function removeAssetStrategy(address _asset, address _strategy) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_asset`|`address`||
|`_strategy`|`address`||


### setDefaultStrategies

Sets the default strategies for a specific asset

*Restricted to admin timelock*


```solidity
function setDefaultStrategies(address _asset, address[] calldata strategies) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_asset`|`address`||
|`strategies`|`address[]`|Array of strategy addresses to set as default|


### _deposit

Internal function to deposit an asset into the vault


```solidity
function _deposit(address asset, address strategy, uint256 amount) internal returns (uint256 deposited);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to deposit|
|`strategy`|`address`|The strategy configuration|
|`amount`|`uint256`|The amount of the asset to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deposited`|`uint256`|The actual amount deposited|


### _withdraw

Internal function to withdraw an asset from the vault


```solidity
function _withdraw(address asset, address strategy, uint256 amount) internal returns (uint256 withdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to withdraw|
|`strategy`|`address`|The strategy configuration|
|`amount`|`uint256`|The amount of the asset to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawn`|`uint256`|The actual amount withdrawn|


### getUnderlyingAssetFor

Returns the underlying asset address for a given receipt token


```solidity
function getUnderlyingAssetFor(address _receiptToken) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_receiptToken`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the underlying asset|


### getDefaultStrategies

Gets the list of default strategies for a specific asset


```solidity
function getDefaultStrategies(address _asset) external view returns (address[] memory strategies);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_asset`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`strategies`|`address[]`|An array of strategy addresses that are set as default for the asset|


### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override requiresAuth;
```

