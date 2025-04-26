# IRewardsManager
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/interfaces/level/IRewardsManager.sol)

**Inherits:**
[IRewardsManagerErrors](/src/v2/interfaces/level/IRewardsManager.sol/interface.IRewardsManagerErrors.md), [IRewardsManagerEvents](/src/v2/interfaces/level/IRewardsManager.sol/interface.IRewardsManagerEvents.md)

Interface for managing rewards distribution across strategies

*Inherits error and event interfaces from IRewardsManagerErrors and IRewardsManagerEvents*


## Functions
### initialize

Initializes the contract with admin and vault addresses


```solidity
function initialize(address admin_, address vault_, address guard_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin_`|`address`|Address of the admin who will have administrative privileges|
|`vault_`|`address`|Address of the vault contract that holds the assets|
|`guard_`|`address`|Address of the guard contract|


### setVault

Sets a new vault address

*Only callable by admin timelock*


```solidity
function setVault(address vault_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault_`|`address`|The new vault address|


### setTreasury

Sets a new treasury address

*Only callable by admin timelock*


```solidity
function setTreasury(address treasury_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`treasury_`|`address`|The new treasury address|


### setAllStrategies

Updates all strategies for a specific asset

*Only callable by admin timelock*


```solidity
function setAllStrategies(address asset, StrategyConfig[] memory strategies) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset for which to set strategies|
|`strategies`|`StrategyConfig[]`|Array of strategy configurations to be set|


### reward

Harvests yield from specified assets and distributes rewards

*Callable by HARVESTER_ROLE*

*Caller must ensure that vault has enough of the first asset in the list to reward*


```solidity
function reward(address[] calldata assets) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|Array of asset addresses to harvest rewards from|


### getAccruedYield

Calculates the total accrued yield for specified assets

*Returns the yield amount in the vault share's decimals*


```solidity
function getAccruedYield(address[] calldata assets) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|Array of asset addresses to calculate yield for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of excess yield accrued to this contract|


### getAllStrategies

Retrieves all strategies for a specific asset


```solidity
function getAllStrategies(address asset) external view returns (StrategyConfig[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`StrategyConfig[]`|Array of strategy configurations|


