# IRewardsManagerEvents
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/level/IRewardsManager.sol)

Interface for event definitions


## Events
### Rewarded
Emitted when a reward is distributed


```solidity
event Rewarded(address asset, address to, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset that was rewarded|
|`to`|`address`|The recipient of the reward|
|`amount`|`uint256`|The amount of the reward|

### StrategiesUpdated
Emitted when strategies are updated


```solidity
event StrategiesUpdated(address asset, StrategyConfig[] strategies);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset for which strategies were updated|
|`strategies`|`StrategyConfig[]`|Array of strategy configurations|

### TreasuryUpdated
Emitted when treasury is updated


```solidity
event TreasuryUpdated(address from, address to);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The previous treasury address|
|`to`|`address`|The new treasury address|

### VaultUpdated
Emitted when vault is updated


```solidity
event VaultUpdated(address from, address to);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The previous vault address|
|`to`|`address`|The new vault address|

### WithdrawDefaultSucceeded
Emitted when withdrawal is successful


```solidity
event WithdrawDefaultSucceeded(address asset, uint256 collateralAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset that was withdrawn|
|`collateralAmount`|`uint256`|The amount of collateral withdrawn|

### WithdrawDefaultFailed
Emitted when withdrawal fails


```solidity
event WithdrawDefaultFailed(address asset, uint256 collateralAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset that was attempted to be withdrawn|
|`collateralAmount`|`uint256`|The amount of collateral that was attempted to be withdrawn|

