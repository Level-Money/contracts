# IRewardsDistributor
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/interfaces/aave/IRewardsDistributor.sol)

**Author:**
Aave

Defines the basic interface for a Rewards Distributor.


## Functions
### setDistributionEnd

*Sets the end date for the distribution*


```solidity
function setDistributionEnd(address asset, address reward, uint32 newDistributionEnd) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset to incentivize|
|`reward`|`address`|The reward token that incentives the asset|
|`newDistributionEnd`|`uint32`|The end date of the incentivization, in unix time format|


### setEmissionPerSecond

*Sets the emission per second of a set of reward distributions*


```solidity
function setEmissionPerSecond(address asset, address[] calldata rewards, uint88[] calldata newEmissionsPerSecond)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset is being incentivized|
|`rewards`|`address[]`|List of reward addresses are being distributed|
|`newEmissionsPerSecond`|`uint88[]`|List of new reward emissions per second|


### getDistributionEnd

*Gets the end date for the distribution*


```solidity
function getDistributionEnd(address asset, address reward) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The incentivized asset|
|`reward`|`address`|The reward token of the incentivized asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The timestamp with the end of the distribution, in unix time format|


### getUserAssetIndex

*Returns the index of a user on a reward distribution*


```solidity
function getUserAssetIndex(address user, address asset, address reward) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|Address of the user|
|`asset`|`address`|The incentivized asset|
|`reward`|`address`|The reward token of the incentivized asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The current user asset index, not including new distributions|


### getRewardsData

*Returns the configuration of the distribution reward for a certain asset*


```solidity
function getRewardsData(address asset, address reward) external view returns (uint256, uint256, uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The incentivized asset|
|`reward`|`address`|The reward token of the incentivized asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The index of the asset distribution|
|`<none>`|`uint256`|The emission per second of the reward distribution|
|`<none>`|`uint256`|The timestamp of the last update of the index|
|`<none>`|`uint256`|The timestamp of the distribution end|


### getAssetIndex

*Calculates the next value of an specific distribution index, with validations.*


```solidity
function getAssetIndex(address asset, address reward) external view returns (uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The incentivized asset|
|`reward`|`address`|The reward token of the incentivized asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The old index of the asset distribution|
|`<none>`|`uint256`|The new index of the asset distribution|


### getRewardsByAsset

*Returns the list of available reward token addresses of an incentivized asset*


```solidity
function getRewardsByAsset(address asset) external view returns (address[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The incentivized asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|List of rewards addresses of the input asset|


### getRewardsList

*Returns the list of available reward addresses*


```solidity
function getRewardsList() external view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|List of rewards supported in this contract|


### getUserAccruedRewards

*Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.*


```solidity
function getUserAccruedRewards(address user, address reward) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`reward`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Unclaimed rewards, not including new distributions|


### getUserRewards

*Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.*


```solidity
function getUserRewards(address[] calldata assets, address user, address reward) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|List of incentivized assets to check eligible distributions|
|`user`|`address`|The address of the user|
|`reward`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The rewards amount|


### getAllUserRewards

*Returns a list all rewards of a user, including already accrued and unrealized claimable rewards*


```solidity
function getAllUserRewards(address[] calldata assets, address user)
    external
    view
    returns (address[] memory, uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|List of incentivized assets to check eligible distributions|
|`user`|`address`|The address of the user|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|The list of reward addresses|
|`<none>`|`uint256[]`|The list of unclaimed amount of rewards|


### getAssetDecimals

*Returns the decimals of an asset to calculate the distribution delta*


```solidity
function getAssetDecimals(address asset) external view returns (uint8);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address to retrieve decimals|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|The decimals of an underlying asset|


### EMISSION_MANAGER

*Returns the address of the emission manager*


```solidity
function EMISSION_MANAGER() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the EmissionManager|


### getEmissionManager

*Returns the address of the emission manager.
Deprecated: This getter is maintained for compatibility purposes. Use the `EMISSION_MANAGER()` function instead.*


```solidity
function getEmissionManager() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the EmissionManager|


## Events
### AssetConfigUpdated
*Emitted when the configuration of the rewards of an asset is updated.*


```solidity
event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 oldEmission,
    uint256 newEmission,
    uint256 oldDistributionEnd,
    uint256 newDistributionEnd,
    uint256 assetIndex
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the incentivized asset|
|`reward`|`address`|The address of the reward token|
|`oldEmission`|`uint256`|The old emissions per second value of the reward distribution|
|`newEmission`|`uint256`|The new emissions per second value of the reward distribution|
|`oldDistributionEnd`|`uint256`|The old end timestamp of the reward distribution|
|`newDistributionEnd`|`uint256`|The new end timestamp of the reward distribution|
|`assetIndex`|`uint256`|The index of the asset distribution|

### Accrued
*Emitted when rewards of an asset are accrued on behalf of a user.*


```solidity
event Accrued(
    address indexed asset,
    address indexed reward,
    address indexed user,
    uint256 assetIndex,
    uint256 userIndex,
    uint256 rewardsAccrued
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the incentivized asset|
|`reward`|`address`|The address of the reward token|
|`user`|`address`|The address of the user that rewards are accrued on behalf of|
|`assetIndex`|`uint256`|The index of the asset distribution|
|`userIndex`|`uint256`|The index of the asset distribution on behalf of the user|
|`rewardsAccrued`|`uint256`|The amount of rewards accrued|

