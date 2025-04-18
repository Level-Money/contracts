# RewardsManager
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/usd/RewardsManager.sol)

**Inherits:**
[RewardsManagerStorage](/src/v2/usd/RewardsManagerStorage.sol/abstract.RewardsManagerStorage.md), Initializable, UUPSUpgradeable, [AuthUpgradeable](/src/v2/auth/AuthUpgradeable.sol/abstract.AuthUpgradeable.md), [PauserGuarded](/src/v2/common/guard/PauserGuarded.sol/abstract.PauserGuarded.md)

Contract for managing rewards distribution across strategies

*Inherits error and event interfaces from IRewardsManagerErrors and IRewardsManagerEvents*

*Inherits interface from IRewardsManager*


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(address admin_, address vault_, address guard_) external initializer;
```

### reward

Harvests yield from specified assets and distributes rewards

*Callable by HARVESTER_ROLE*


```solidity
function reward(address[] calldata assets) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|Array of asset addresses to harvest rewards from|


### setVault

Sets a new vault address

*Only callable by admin timelock*


```solidity
function setVault(address vault_) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault_`|`address`|The new vault address|


### setTreasury

Sets a new treasury address

*Only callable by admin timelock*


```solidity
function setTreasury(address treasury_) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`treasury_`|`address`|The new treasury address|


### setAllStrategies

Updates all strategies for a specific asset

*Only callable by admin timelock*


```solidity
function setAllStrategies(address asset, StrategyConfig[] memory strategies) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset for which to set strategies|
|`strategies`|`StrategyConfig[]`|Array of strategy configurations to be set|


### getAccruedYield

Calculates the total accrued yield for specified assets

*Returns the yield amount in the vault share's decimals*


```solidity
function getAccruedYield(address[] calldata assets) public view returns (uint256 accrued);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|Array of asset addresses to calculate yield for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`accrued`|`uint256`|Amount of excess yield accrued to this contract|


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


### getTotalAssets

Returns the total assets in the vault for a given asset, to the asset's precision


```solidity
function getTotalAssets(address asset) external view returns (uint256 assets);
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override requiresAuth;
```

### setGuard


```solidity
function setGuard(address guard_) external requiresAuth;
```

