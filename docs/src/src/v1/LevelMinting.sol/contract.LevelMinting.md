# LevelMinting
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/LevelMinting.sol)

**Inherits:**
[ILevelMinting](/src/v1/interfaces/ILevelMinting.sol/interface.ILevelMinting.md), [SingleAdminAccessControl](/src/v1/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md), ReentrancyGuard

solhint-disable private-vars-leading-underscore

This contract issues and redeems lvlUSD for/from other accepted stablecoins

*Changelog: change name to LevelMinting and lvlUSD, update solidity versions*


## State Variables
### GATEKEEPER_ROLE
role enabling to disable mint and redeem


```solidity
bytes32 private constant GATEKEEPER_ROLE = keccak256("GATEKEEPER_ROLE");
```


### MINTER_ROLE
role for minting lvlUSD


```solidity
bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
```


### REDEEMER_ROLE
role for redeeming lvlUSD


```solidity
bytes32 private constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");
```


### lvlusd
lvlusd stablecoin


```solidity
IlvlUSD public immutable lvlusd;
```


### _supportedAssets
Supported assets


```solidity
EnumerableSet.AddressSet internal _supportedAssets;
```


### _redeemableAssets
Redeemable assets


```solidity
EnumerableSet.AddressSet internal _redeemableAssets;
```


### _reserveAddresses

```solidity
EnumerableSet.AddressSet internal _reserveAddresses;
```


### mintedPerBlock
lvlUSD minted per block


```solidity
mapping(uint256 => uint256) public mintedPerBlock;
```


### redeemedPerBlock
lvlUSD redeemed per block


```solidity
mapping(uint256 => uint256) public redeemedPerBlock;
```


### maxMintPerBlock
max minted lvlUSD allowed per block


```solidity
uint256 public maxMintPerBlock;
```


### maxRedeemPerBlock
max redeemed lvlUSD allowed per block


```solidity
uint256 public maxRedeemPerBlock;
```


### checkMinterRole

```solidity
bool public checkMinterRole = false;
```


### checkRedeemerRole

```solidity
bool public checkRedeemerRole = false;
```


### MAX_COOLDOWN_DURATION

```solidity
uint24 public constant MAX_COOLDOWN_DURATION = 21 days;
```


### cooldownDuration

```solidity
uint24 public cooldownDuration;
```


### cooldowns

```solidity
mapping(address => mapping(address => UserCooldown)) public cooldowns;
```


### pendingRedemptionlvlUSDAmounts

```solidity
mapping(address => uint256) public pendingRedemptionlvlUSDAmounts;
```


### _route

```solidity
Route _route;
```


### oracles

```solidity
mapping(address => address) public oracles;
```


### heartbeats

```solidity
mapping(address => uint256) public heartbeats;
```


### DEFAULT_HEART_BEAT

```solidity
uint256 public DEFAULT_HEART_BEAT = 86400;
```


## Functions
### belowMaxMintPerBlock

ensure that the already minted lvlUSD in the actual block plus the amount to be minted is below the maxMintPerBlock var


```solidity
modifier belowMaxMintPerBlock(uint256 mintAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`mintAmount`|`uint256`|The lvlUSD amount to be minted|


### belowMaxRedeemPerBlock

ensure that the already redeemed lvlUSD in the actual block plus the amount to be redeemed is below the maxRedeemPerBlock var


```solidity
modifier belowMaxRedeemPerBlock(uint256 redeemAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`redeemAmount`|`uint256`|The lvlUSD amount to be redeemed|


### onlyMinterWhenEnabled


```solidity
modifier onlyMinterWhenEnabled();
```

### onlyRedeemerWhenEnabled


```solidity
modifier onlyRedeemerWhenEnabled();
```

### ensureCooldownOff

ensure cooldownDuration is zero


```solidity
modifier ensureCooldownOff();
```

### ensureCooldownOn

ensure cooldownDuration is gt 0


```solidity
modifier ensureCooldownOn();
```

### constructor


```solidity
constructor(
    IlvlUSD _lvlusd,
    address[] memory _assets,
    address[] memory _oracles,
    address[] memory _reserves,
    uint256[] memory _ratios,
    address _admin,
    uint256 _maxMintPerBlock,
    uint256 _maxRedeemPerBlock
);
```

### _mint

Mint stablecoins from assets


```solidity
function _mint(Order memory order, Route memory route)
    internal
    nonReentrant
    belowMaxMintPerBlock(order.lvlusd_amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`Order`|struct containing order details and confirmation from server|
|`route`|`Route`|the addresses to which the collateral should be sent (and ratios describing the amount to send to each address)|


### mint


```solidity
function mint(Order memory order, Route calldata route) external virtual onlyMinterWhenEnabled;
```

### mintDefault


```solidity
function mintDefault(Order memory order) external virtual onlyMinterWhenEnabled;
```

### setCooldownDuration


```solidity
function setCooldownDuration(uint24 newDuration) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### _redeem

Redeem stablecoins for assets


```solidity
function _redeem(Order memory order) internal nonReentrant belowMaxRedeemPerBlock(order.lvlusd_amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`Order`|struct containing order details and confirmation from server|


### computeCollateralOrlvlUSDAmount


```solidity
function computeCollateralOrlvlUSDAmount(Order memory order) private view returns (Order memory);
```

### initiateRedeem


```solidity
function initiateRedeem(Order memory order) external ensureCooldownOn onlyRedeemerWhenEnabled;
```

### completeRedeem


```solidity
function completeRedeem(address token) external virtual onlyRedeemerWhenEnabled;
```

### redeem


```solidity
function redeem(Order memory order) external virtual ensureCooldownOff onlyRedeemerWhenEnabled;
```

### setMaxMintPerBlock

Sets the max mintPerBlock limit


```solidity
function setMaxMintPerBlock(uint256 _maxMintPerBlock) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setMaxRedeemPerBlock

Sets the max redeemPerBlock limit


```solidity
function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### disableMintRedeem

Disables the mint and redeem


```solidity
function disableMintRedeem() external onlyRole(GATEKEEPER_ROLE);
```

### transferToReserve

transfers an asset to a reserve wallet


```solidity
function transferToReserve(address wallet, address asset, uint256 amount)
    external
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE);
```

### removeSupportedAsset

Removes an asset from the supported assets list


```solidity
function removeSupportedAsset(address asset) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### removeRedeemableAssets


```solidity
function removeRedeemableAssets(address asset) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### isSupportedAsset

Checks if an asset is supported.


```solidity
function isSupportedAsset(address asset) external view returns (bool);
```

### removeReserveAddress

Removes a reserve from the reserve address list


```solidity
function removeReserveAddress(address reserve) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### removeMinterRole

Removes the minter role from an account, this can ONLY be executed by the gatekeeper role


```solidity
function removeMinterRole(address minter) external onlyRole(GATEKEEPER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minter`|`address`|The address to remove the minter role from|


### removeRedeemerRole

Removes the redeemer role from an account, this can ONLY be executed by the gatekeeper role


```solidity
function removeRedeemerRole(address redeemer) external onlyRole(GATEKEEPER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`redeemer`|`address`|The address to remove the redeemer role from|


### getPriceAndDecimals


```solidity
function getPriceAndDecimals(address collateralToken) public view returns (int256, uint256);
```

### addSupportedAsset

Adds an asset to the supported assets list.


```solidity
function addSupportedAsset(address asset) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### addOracle


```solidity
function addOracle(address collateral, address oracle) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### setHeartBeat


```solidity
function setHeartBeat(address collateral, uint256 heartBeat) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### addReserveAddress

Adds a reserve to the supported reserves list.


```solidity
function addReserveAddress(address reserve) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### verifyOrder

assert validity of order


```solidity
function verifyOrder(Order memory order) public pure override returns (bool);
```

### verifyRatios


```solidity
function verifyRatios(uint256[] memory ratios) public pure returns (bool);
```

### verifyRoute

assert validity of route object per type


```solidity
function verifyRoute(Route memory route, OrderType orderType) public view override returns (bool);
```

### setCheckMinterRole


```solidity
function setCheckMinterRole(bool _check) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setCheckRedeemerRole


```solidity
function setCheckRedeemerRole(bool _check) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setRoute


```solidity
function setRoute(address[] memory _reserves, uint256[] memory _ratios) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### _transferToBeneficiary

transfer supported asset to beneficiary address


```solidity
function _transferToBeneficiary(address beneficiary, address asset, uint256 amount) internal;
```

### _transferCollateral

transfer supported asset to array of reserve addresses per defined ratio


```solidity
function _transferCollateral(
    uint256 amount,
    address asset,
    address benefactor,
    address[] memory addresses,
    uint256[] memory ratios
) internal;
```

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

