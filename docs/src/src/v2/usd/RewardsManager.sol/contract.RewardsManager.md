# RewardsManager
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/usd/RewardsManager.sol)

**Inherits:**
[RewardsManagerStorage](/src/v2/usd/RewardsManagerStorage.sol/abstract.RewardsManagerStorage.md), Initializable, UUPSUpgradeable, [AuthUpgradeable](/src/v2/auth/AuthUpgradeable.sol/abstract.AuthUpgradeable.md), [PauserGuardedUpgradable](/src/v2/common/guard/PauserGuardedUpgradable.sol/abstract.PauserGuardedUpgradable.md)

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
function reward(address redemptionAsset, uint256 yieldAmount) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`redemptionAsset`|`address`|The address of the base collateral to withdraw from the vault|
|`yieldAmount`|`uint256`|The amount of yield to distribute in the redemption asset's precision.|


### setVault

Sets a new vault address

*Only callable by owner (admin timelock)*


```solidity
function setVault(address vault_) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vault_`|`address`|The new vault address|


### setTreasury

Sets a new treasury address

*Only callable by owner (admin timelock)*


```solidity
function setTreasury(address treasury_) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`treasury_`|`address`|The new treasury address|


### setAllStrategies

Updates all strategies for a specific asset

*Only callable by owner (admin timelock)*


```solidity
function setAllStrategies(address asset, StrategyConfig[] memory strategies) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset for which to set strategies|
|`strategies`|`StrategyConfig[]`|Array of strategy configurations to be set|


### setAllBaseCollateral

Sets the base collateral

*Only callable by owner (admin timelock)*


```solidity
function setAllBaseCollateral(address[] calldata _allBaseCollateral) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_allBaseCollateral`|`address[]`|Array of base collateral addresses|


### setGuard


```solidity
function setGuard(address guard_) external requiresAuth;
```

### updateOracle

Updates the oracle for a specific asset

*Only callable by owner (admin timelock)*


```solidity
function updateOracle(address collateral, address oracle) external notPaused requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the asset|
|`oracle`|`address`|The new oracle address|


### getAccruedYield

Calculates the total accrued yield for specified assets

*the assets array should always be base tokens (USDC, USDT, etc.)*


```solidity
function getAccruedYield(address[] memory assets) public returns (uint256 accrued);
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

Retrieves the total assets for a specific asset


```solidity
function getTotalAssets(address asset) external view returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|Total assets for the asset|


### _inAllBaseCollateral

Checks if an asset is in the allBaseCollateral array


```solidity
function _inAllBaseCollateral(address asset) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the asset is in the allBaseCollateral array, false otherwise|


### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override requiresAuth;
```

