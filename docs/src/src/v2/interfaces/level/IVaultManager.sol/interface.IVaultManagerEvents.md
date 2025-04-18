# IVaultManagerEvents
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/level/IVaultManager.sol)

Event interface for the VaultManager contract


## Events
### VaultAddressChanged
Emitted when the vault address is changed


```solidity
event VaultAddressChanged(address indexed from, address indexed to);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The previous vault address|
|`to`|`address`|The new vault address|

### BaseCollateralAdded
Emitted when a new base collateral is added


```solidity
event BaseCollateralAdded(address indexed asset);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the new base collateral|

### BaseCollateralRemoved
Emitted when a base collateral is removed


```solidity
event BaseCollateralRemoved(address indexed asset);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the base collateral to be removed|

### AssetStrategyAdded
Emitted when a new strategy is added for a specific asset


```solidity
event AssetStrategyAdded(address indexed asset, address indexed strategy, StrategyConfig config);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategy`|`address`|The address of the strategy to add|
|`config`|`StrategyConfig`|Configuration parameters for the strategy|

### AssetStrategyRemoved
Emitted when a strategy is removed for a specific asset


```solidity
event AssetStrategyRemoved(address indexed asset, address indexed strategy);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategy`|`address`|The address of the strategy to remove|

### DefaultStrategiesSet
Emitted when default strategies are set for a specific asset


```solidity
event DefaultStrategiesSet(address indexed asset, address[] strategies);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategies`|`address[]`|Array of strategy addresses to be set as default|

### Deposit
Emitted when an asset is deposited into a strategy


```solidity
event Deposit(address indexed asset, StrategyConfig strategy, uint256 deposited);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategy`|`StrategyConfig`|The strategy configuration|
|`deposited`|`uint256`|The amount of the asset deposited|

### Withdraw
Emitted when an asset is withdrawn from a strategy


```solidity
event Withdraw(address indexed asset, StrategyConfig strategy, uint256 withdrawn);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`strategy`|`StrategyConfig`|The strategy configuration|
|`withdrawn`|`uint256`|The amount of the asset withdrawn|

