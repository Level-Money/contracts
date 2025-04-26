# ILevelMintingV2
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/interfaces/level/ILevelMintingV2.sol)

**Inherits:**
[ILevelMintingV2Events](/src/v2/interfaces/level/ILevelMintingV2.sol/interface.ILevelMintingV2Events.md), [ILevelMintingV2Errors](/src/v2/interfaces/level/ILevelMintingV2.sol/interface.ILevelMintingV2Errors.md), [ILevelMintingV2Structs](/src/v2/interfaces/level/ILevelMintingV2.sol/interface.ILevelMintingV2Structs.md)

Interface for the Level Protocol's minting and redemption functionality

*Inherits events, errors, and structs from respective interfaces*


## Functions
### mint

Mints lvlUSD stablecoin based on the provided order parameters


```solidity
function mint(Order calldata order) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`Order`|The Order struct containing mint parameters|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of lvlUSD minted|


### initiateRedeem

Initiates the redemption process for lvlUSD


```solidity
function initiateRedeem(address asset, uint256 lvlusdAmount, uint256 expectedAmount)
    external
    returns (uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to redeem for|
|`lvlusdAmount`|`uint256`|The amount of lvlUSD to redeem|
|`expectedAmount`|`uint256`|The minimum amount of asset expected to receive|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|First return value likely represents a redemption ID or status|
|`<none>`|`uint256`|Second return value likely represents the actual amount to be redeemed|


### completeRedeem

Completes the redemption process after cooldown period


```solidity
function completeRedeem(address asset, address beneficiary) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to redeem for|
|`beneficiary`|`address`|The address that will receive the redeemed assets|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of the asset redeemed|


### setVaultManager

Sets the vault manager address


```solidity
function setVaultManager(address _vaultManager) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vaultManager`|`address`|The address of the new vault manager|


### setMaxMintPerBlock

Sets the maximum amount that can be minted in a single block


```solidity
function setMaxMintPerBlock(uint256 _maxMintPerBlock) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxMintPerBlock`|`uint256`|The new maximum mint amount per block|


### setMaxRedeemPerBlock

Sets the maximum amount that can be redeemed in a single block


```solidity
function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxRedeemPerBlock`|`uint256`|The new maximum redeem amount per block|


### setCooldownDuration

Sets the duration of the cooldown period for redemptions


```solidity
function setCooldownDuration(uint256 newduration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newduration`|`uint256`|The new cooldown duration in seconds|


### disableMintRedeem

Disables both minting and redemption functionality

*Likely an emergency function restricted to admin or guardian roles*


```solidity
function disableMintRedeem() external;
```

### addMintableAsset

Adds an asset to the list of assets that can be used for minting


```solidity
function addMintableAsset(address asset) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to add as mintable|


### removeMintableAsset

Removes an asset from the list of assets that can be used for minting


```solidity
function removeMintableAsset(address asset) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to remove from mintable assets|


### addRedeemableAsset

Adds an asset to the list of assets that can be redeemed


```solidity
function addRedeemableAsset(address asset) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to add as redeemable|


### removeRedeemableAsset

Removes an asset from the list of assets that can be redeemed


```solidity
function removeRedeemableAsset(address asset) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to remove from redeemable assets|


### setBaseCollateral

Sets whether an asset is considered a base collateral


```solidity
function setBaseCollateral(address asset, bool isBase) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`isBase`|`bool`|if the asset should be set as base collateral|


### addOracle

Adds a price oracle for a collateral asset


```solidity
function addOracle(address collateral, address oracle, bool _isLevelOracle) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral asset|
|`oracle`|`address`|The address of the price oracle|
|`_isLevelOracle`|`bool`|if this is a Level Protocol oracle|


### removeOracle

Removes a price oracle for a collateral asset


```solidity
function removeOracle(address collateral) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral asset to remove oracle for|


### setHeartBeat

Sets the heartbeat duration (the max time that a price oracle can be stale) for a collateral asset's oracle.


```solidity
function setHeartBeat(address collateral, uint256 heartBeat) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral asset|
|`heartBeat`|`uint256`|The new heartbeat duration|


