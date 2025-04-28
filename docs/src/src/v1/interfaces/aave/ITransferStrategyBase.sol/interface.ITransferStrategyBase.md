# ITransferStrategyBase
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/interfaces/aave/ITransferStrategyBase.sol)


## Functions
### performTransfer

*Perform custom transfer logic via delegate call from source contract to a TransferStrategy implementation*


```solidity
function performTransfer(address to, address reward, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Account to transfer rewards|
|`reward`|`address`|Address of the reward token|
|`amount`|`uint256`|Amount to transfer to the "to" address parameter|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Returns true bool if transfer logic succeeds|


### getIncentivesController


```solidity
function getIncentivesController() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Returns the address of the Incentives Controller|


### getRewardsAdmin


```solidity
function getRewardsAdmin() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Returns the address of the Rewards admin|


### emergencyWithdrawal

*Perform an emergency token withdrawal only callable by the Rewards admin*


```solidity
function emergencyWithdrawal(address token, address to, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the token to withdraw funds from this contract|
|`to`|`address`|Address of the recipient of the withdrawal|
|`amount`|`uint256`|Amount of the withdrawal|


## Events
### EmergencyWithdrawal

```solidity
event EmergencyWithdrawal(address indexed caller, address indexed token, address indexed to, uint256 amount);
```

