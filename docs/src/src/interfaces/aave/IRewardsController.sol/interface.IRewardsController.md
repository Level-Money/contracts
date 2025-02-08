# IRewardsController
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/interfaces/aave/IRewardsController.sol)

**Inherits:**
[IRewardsDistributor](/src/interfaces/aave/IRewardsDistributor.sol/interface.IRewardsDistributor.md)

**Author:**
Aave

Defines the basic interface for a Rewards Controller.


## Functions
### setClaimer

*Whitelists an address to claim the rewards on behalf of another address*


```solidity
function setClaimer(address user, address claimer) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`claimer`|`address`|The address of the claimer|


### setTransferStrategy

*Sets a TransferStrategy logic contract that determines the logic of the rewards transfer*


```solidity
function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`address`|The address of the reward token|
|`transferStrategy`|`ITransferStrategyBase`|The address of the TransferStrategy logic contract|


### setRewardOracle

At the moment of reward configuration, the Incentives Controller performs
a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
This check is enforced for integrators to be able to show incentives at
the current Aave UI without the need to setup an external price registry

*Sets an Aave Oracle contract to enforce rewards with a source of value.*


```solidity
function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`address`|The address of the reward to set the price aggregator|
|`rewardOracle`|`IEACAggregatorProxy`|The address of price aggregator that follows IEACAggregatorProxy interface|


### getRewardOracle

*Get the price aggregator oracle address*


```solidity
function getRewardOracle(address reward) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`address`|The address of the reward|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The price oracle of the reward|


### getClaimer

*Returns the whitelisted claimer for a certain address (0x0 if not set)*


```solidity
function getClaimer(address user) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The claimer address|


### getTransferStrategy

*Returns the Transfer Strategy implementation contract address being used for a reward address*


```solidity
function getTransferStrategy(address reward) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`address`|The address of the reward|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the TransferStrategy contract|


### configureAssets

*Configure assets to incentivize with an emission of rewards per second until the end of distribution.*


```solidity
function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`config`|`RewardsDataTypes.RewardsConfigInput[]`|The assets configuration input, the list of structs contains the following fields: uint104 emissionPerSecond: The emission per second following rewards unit decimals. uint256 totalSupply: The total supply of the asset to incentivize uint40 distributionEnd: The end of the distribution of the incentives for an asset address asset: The asset address to incentivize address reward: The reward token address ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic. IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend. Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.|


### handleAction

*Called by the corresponding asset on transfer hook in order to update the rewards distribution.*

*The units of `totalSupply` and `userBalance` should be the same.*


```solidity
function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user whose asset balance has changed|
|`totalSupply`|`uint256`|The total supply of the asset prior to user balance change|
|`userBalance`|`uint256`|The previous user balance prior to balance change|


### claimRewards

*Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards*


```solidity
function claimRewards(address[] calldata assets, uint256 amount, address to, address reward)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|List of assets to check eligible distributions before claiming rewards|
|`amount`|`uint256`|The amount of rewards to claim|
|`to`|`address`|The address that will be receiving the rewards|
|`reward`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of rewards claimed|


### claimRewardsOnBehalf

*Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager*


```solidity
function claimRewardsOnBehalf(address[] calldata assets, uint256 amount, address user, address to, address reward)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|The list of assets to check eligible distributions before claiming rewards|
|`amount`|`uint256`|The amount of rewards to claim|
|`user`|`address`|The address to check and claim rewards|
|`to`|`address`|The address that will be receiving the rewards|
|`reward`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of rewards claimed|


### claimRewardsToSelf

*Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards*


```solidity
function claimRewardsToSelf(address[] calldata assets, uint256 amount, address reward) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|The list of assets to check eligible distributions before claiming rewards|
|`amount`|`uint256`|The amount of rewards to claim|
|`reward`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of rewards claimed|


### claimAllRewards

*Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards*


```solidity
function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|The list of assets to check eligible distributions before claiming rewards|
|`to`|`address`|The address that will be receiving the rewards|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardsList`|`address[]`|List of addresses of the reward tokens|
|`claimedAmounts`|`uint256[]`|List that contains the claimed amount per reward, following same order as "rewardList"|


### claimAllRewardsOnBehalf

*Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager*


```solidity
function claimAllRewardsOnBehalf(address[] calldata assets, address user, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|The list of assets to check eligible distributions before claiming rewards|
|`user`|`address`|The address to check and claim rewards|
|`to`|`address`|The address that will be receiving the rewards|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardsList`|`address[]`|List of addresses of the reward tokens|
|`claimedAmounts`|`uint256[]`|List that contains the claimed amount per reward, following same order as "rewardsList"|


### claimAllRewardsToSelf

*Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards*


```solidity
function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|The list of assets to check eligible distributions before claiming rewards|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardsList`|`address[]`|List of addresses of the reward tokens|
|`claimedAmounts`|`uint256[]`|List that contains the claimed amount per reward, following same order as "rewardsList"|


## Events
### ClaimerSet
*Emitted when a new address is whitelisted as claimer of rewards on behalf of a user*


```solidity
event ClaimerSet(address indexed user, address indexed claimer);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`claimer`|`address`|The address of the claimer|

### RewardsClaimed
*Emitted when rewards are claimed*


```solidity
event RewardsClaimed(address indexed user, address indexed reward, address indexed to, address claimer, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user rewards has been claimed on behalf of|
|`reward`|`address`|The address of the token reward is claimed|
|`to`|`address`|The address of the receiver of the rewards|
|`claimer`|`address`|The address of the claimer|
|`amount`|`uint256`|The amount of rewards claimed|

### TransferStrategyInstalled
*Emitted when a transfer strategy is installed for the reward distribution*


```solidity
event TransferStrategyInstalled(address indexed reward, address indexed transferStrategy);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`address`|The address of the token reward|
|`transferStrategy`|`address`|The address of TransferStrategy contract|

### RewardOracleUpdated
*Emitted when the reward oracle is updated*


```solidity
event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`address`|The address of the token reward|
|`rewardOracle`|`address`|The address of oracle|

