# LevelMintingV2
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/LevelMintingV2.sol)

**Inherits:**
[LevelMintingV2Storage](/src/v2/LevelMintingV2Storage.sol/abstract.LevelMintingV2Storage.md), Initializable, UUPSUpgradeable, [AuthUpgradeable](/src/v2/auth/AuthUpgradeable.sol/abstract.AuthUpgradeable.md), [PauserGuardedUpgradable](/src/v2/common/guard/PauserGuardedUpgradable.sol/abstract.PauserGuardedUpgradable.md)

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

Contract for minting and redeeming lvlUSD


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(
    address _admin,
    uint256 _maxMintPerBlock,
    uint256 _maxRedeemPerBlock,
    address _authority,
    address _vaultManager,
    address _guard
) external initializer;
```

### mint

If not public, callable by MINTER_ROLE


```solidity
function mint(Order calldata order) external requiresAuth notPaused returns (uint256 lvlUsdMinted);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`Order`|The Order struct containing mint parameters|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lvlUsdMinted`|`uint256`|The amount of lvlUSD minted|


### initiateRedeem

If not public, callable by REDEEMER_ROLE

*Redemptions must only occur in base assets*


```solidity
function initiateRedeem(address asset, uint256 lvlUsdAmount, uint256 minAssetAmount)
    external
    requiresAuth
    notPaused
    returns (uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to redeem for|
|`lvlUsdAmount`|`uint256`||
|`minAssetAmount`|`uint256`|The minimum amount of asset expected to receive|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|First return value likely represents a redemption ID or status|
|`<none>`|`uint256`|Second return value likely represents the actual amount to be redeemed|


### completeRedeem

Completes the redemption process after cooldown period

*Collateral sent to the silo may be locked if the address is denylisted after initiating redemption*


```solidity
function completeRedeem(address asset, address beneficiary) external notPaused returns (uint256 collateralAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to redeem for|
|`beneficiary`|`address`|The address that will receive the redeemed assets|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount`|`uint256`|The amount of the asset redeemed|


### setGuard


```solidity
function setGuard(address _guard) external requiresAuth;
```

### verifyOrder

assert validity of order


```solidity
function verifyOrder(Order memory order) public view;
```

### computeMint

Converts collateralAmount to lvlUSD amount to mint

*This function could take in either a base collateral (ie USDC/USDT) or a receipt token (ie Morpho vault share, aUSDC/T)*

*If we receive a receipt token, we need to first convert the receipt token to the amount of underlying it can be redeemd for*

*before applying the underlying's USD price and calculating the lvlUSD amount to mint*


```solidity
function computeMint(address collateralAsset, uint256 collateralAmount) public view returns (uint256 lvlusdAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAsset`|`address`|The collateral asset to convert|
|`collateralAmount`|`uint256`|The amount of collateral to convert|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lvlusdAmount`|`uint256`|The amount of lvlUSD to mint|


### computeRedeem

Converts lvlUSD amount to redeem to collateral amount


```solidity
function computeRedeem(address asset, uint256 lvlusdAmount) public view returns (uint256 collateralAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset to convert|
|`lvlusdAmount`|`uint256`|The amount of lvlUSD to convert|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount`|`uint256`|The amount of collateral to redeem|


### getPriceAndDecimals

Gets the price and decimals of a collateral token


```solidity
function getPriceAndDecimals(address collateralToken) public view returns (int256 price, uint256 decimal);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralToken`|`address`|The collateral token to get the price and decimals for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`int256`|The price of the collateral token|
|`decimal`|`uint256`|The decimals of the collateral token|


### setMaxMintPerBlock

Callable by owner


```solidity
function setMaxMintPerBlock(uint256 _maxMintPerBlock) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxMintPerBlock`|`uint256`|The new maximum mint amount per block|


### setMaxRedeemPerBlock

Callable by owner


```solidity
function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxRedeemPerBlock`|`uint256`|The new maximum redeem amount per block|


### disableMintRedeem

Callable by GATEKEEPER_ROLE and owner

*Likely an emergency function restricted to admin or guardian roles*


```solidity
function disableMintRedeem() external requiresAuth;
```

### setBaseCollateral

Callable by owner


```solidity
function setBaseCollateral(address asset, bool isBase) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset|
|`isBase`|`bool`|if the asset should be set as base collateral|


### addMintableAsset

Callable by owner


```solidity
function addMintableAsset(address asset) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to add as mintable|


### addRedeemableAsset

Callable by owner


```solidity
function addRedeemableAsset(address asset) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to add as redeemable|


### removeMintableAsset

Removes an asset from the list of assets that can be used for minting


```solidity
function removeMintableAsset(address asset) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to remove from mintable assets|


### removeRedeemableAsset

Removes an asset from the list of assets that can be redeemed


```solidity
function removeRedeemableAsset(address asset) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to remove from redeemable assets|


### addOracle

Adds a price oracle for a collateral asset

*Callable by owner*


```solidity
function addOracle(address collateral, address oracle, bool _isLevelOracle) external requiresAuth;
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
function removeOracle(address collateral) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral asset to remove oracle for|


### setHeartBeat

Sets the heartbeat duration (the max time that a price oracle can be stale) for a collateral asset's oracle.

*Callable by owner*


```solidity
function setHeartBeat(address collateral, uint256 heartBeat) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral asset|
|`heartBeat`|`uint256`|The new heartbeat duration|


### setCooldownDuration

Sets the duration of the cooldown period for redemptions

*Callable by owner*


```solidity
function setCooldownDuration(uint256 newduration) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newduration`|`uint256`|The new cooldown duration in seconds|


### setVaultManager

Sets the vault manager address

*Callable by owner*


```solidity
function setVaultManager(address _vaultManager) external requiresAuth;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vaultManager`|`address`|The address of the new vault manager|


### _setMaxMintPerBlock

Sets the max mintPerBlock limit


```solidity
function _setMaxMintPerBlock(uint256 _maxMintPerBlock) internal;
```

### _setMaxRedeemPerBlock

Sets the max redeemPerBlock limit


```solidity
function _setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) internal;
```

### _authorizeUpgrade

*Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeToAndCall}.
Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
```solidity
function _authorizeUpgrade(address) internal onlyOwner {}
```*


```solidity
function _authorizeUpgrade(address newImplementation) internal override requiresAuth;
```

