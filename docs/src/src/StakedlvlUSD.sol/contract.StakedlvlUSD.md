# StakedlvlUSD
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/StakedlvlUSD.sol)

**Inherits:**
[SingleAdminAccessControl](/src/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md), ReentrancyGuard, ERC20Permit, ERC4626, [IStakedlvlUSD](/src/interfaces/IStakedlvlUSD.sol/interface.IStakedlvlUSD.md), [IStakedlvlUSDCooldown](/src/interfaces/IStakedlvlUSDCooldown.sol/interface.IStakedlvlUSDCooldown.md)

The StakedlvlUSD contract allows users to stake lvlUSD tokens to earn dollar-denominated
base + AVS yields from onchain lending protocols. The contract also has an optional cooldown
period for withdrawing staked assets.

Forked from Ethena's StakedUSDe contract.


## State Variables
### REWARDER_ROLE
The role that is allowed to distribute rewards to this contract


```solidity
bytes32 private constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
```


### DENYLIST_MANAGER_ROLE
The role that is allowed to blacklist and un-blacklist addresses


```solidity
bytes32 private constant DENYLIST_MANAGER_ROLE = keccak256("DENYLIST_MANAGER_ROLE");
```


### SOFT_RESTRICTED_STAKER_ROLE
The role which prevents an address to stake


```solidity
bytes32 private constant SOFT_RESTRICTED_STAKER_ROLE = keccak256("SOFT_RESTRICTED_STAKER_ROLE");
```


### FULL_RESTRICTED_STAKER_ROLE
The role which prevents an address to transfer, stake, or unstake. The owner of the contract can redirect address staking balance if an address is in full restricting mode.


```solidity
bytes32 private constant FULL_RESTRICTED_STAKER_ROLE = keccak256("FULL_RESTRICTED_STAKER_ROLE");
```


### VESTING_PERIOD
The vesting period of lastDistributionAmount over which it increasingly becomes available to stakers


```solidity
uint256 private constant VESTING_PERIOD = 8 hours;
```


### MIN_SHARES
Minimum non-zero shares amount to prevent donation attack


```solidity
uint256 private constant MIN_SHARES = 1 ether;
```


### cooldowns

```solidity
mapping(address => UserCooldown) public cooldowns;
```


### MAX_COOLDOWN_DURATION

```solidity
uint24 public constant MAX_COOLDOWN_DURATION = 90 days;
```


### cooldownDuration

```solidity
uint24 public cooldownDuration;
```


### silo

```solidity
slvlUSDSilo public silo;
```


### vestingAmount
The amount of the last asset distribution from the controller contract into this
contract + any unvested remainder at that time


```solidity
uint256 public vestingAmount;
```


### lastDistributionTimestamp
The timestamp of the last asset distribution from the controller contract into this contract


```solidity
uint256 public lastDistributionTimestamp;
```


## Functions
### notZero

ensure input amount nonzero


```solidity
modifier notZero(uint256 amount);
```

### notOwner

ensures blacklist target is not owner


```solidity
modifier notOwner(address target);
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

Constructor for StakedlvlUSD contract.


```solidity
constructor(IERC20 _asset, address _initialRewarder, address _owner)
    ERC20("Staked lvlUSD", "slvlUSD")
    ERC4626(_asset)
    ERC20Permit("slvlUSD");
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_asset`|`IERC20`|The address of the lvlUSD token.|
|`_initialRewarder`|`address`|The address of the initial rewarder.|
|`_owner`|`address`|The address of the admin role.|


### transferInRewards

Allows the owner to transfer rewards from the controller contract into this contract.


```solidity
function transferInRewards(uint256 amount) external nonReentrant onlyRole(REWARDER_ROLE) notZero(amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of rewards to transfer.|


### addToDenylist

Allows the owner (DEFAULT_ADMIN_ROLE) and blacklist managers to blacklist addresses.


```solidity
function addToDenylist(address target, bool isFullDenylisting)
    external
    onlyRole(DENYLIST_MANAGER_ROLE)
    notOwner(target);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address to blacklist.|
|`isFullDenylisting`|`bool`|Soft or full blacklisting level.|


### removeFromDenylist

Allows the owner (DEFAULT_ADMIN_ROLE) and blacklist managers to un-blacklist addresses.


```solidity
function removeFromDenylist(address target, bool isFullDenylisting) external onlyRole(DENYLIST_MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address to un-blacklist.|
|`isFullDenylisting`|`bool`|Soft or full blacklisting level.|


### rescueTokens

Allows the owner to rescue tokens accidentally sent to the contract.
Note that the owner cannot rescue lvlUSD tokens because they functionally sit here
and belong to stakers but can rescue staked lvlUSD as they should never actually
sit in this contract and a staker may well transfer them here by accident.


```solidity
function rescueTokens(address token, uint256 amount, address to) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to be rescued.|
|`amount`|`uint256`|The amount of tokens to be rescued.|
|`to`|`address`|Where to send rescued tokens|


### redistributeLockedAmount

*Burns the full restricted user amount and mints to the desired owner address.*


```solidity
function redistributeLockedAmount(address from, address to) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address to burn the entire balance, with the FULL_RESTRICTED_STAKER_ROLE|
|`to`|`address`|The address to mint the entire balance of "from" parameter.|


### unstake

Claim the staking amount after the cooldown has finished. The address can only retire the full amount of assets.

*unstake can be called after cooldown have been set to 0, to let accounts to be able to claim remaining assets locked at Silo*


```solidity
function unstake(address receiver) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|Address to send the assets by the staker|


### cooldownAssets

redeem assets and starts a cooldown to claim the converted underlying asset


```solidity
function cooldownAssets(uint256 assets) external ensureCooldownOn returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|assets to redeem|


### cooldownShares

redeem shares into assets and starts a cooldown to claim the converted underlying asset


```solidity
function cooldownShares(uint256 shares) external ensureCooldownOn returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|shares to redeem|


### setCooldownDuration

Set cooldown duration. If cooldown duration is set to zero, the StakedlvlUSDV2 behavior changes to follow ERC4626 standard and disables cooldownShares and cooldownAssets methods. If cooldown duration is greater than zero, the ERC4626 withdrawal and redeem functions are disabled, breaking the ERC4626 standard, and enabling the cooldownShares and the cooldownAssets functions.


```solidity
function setCooldownDuration(uint24 duration) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint24`|Duration of the cooldown|


### totalAssets

Returns the amount of lvlUSD tokens that are vested in the contract.


```solidity
function totalAssets() public view override returns (uint256);
```

### getUnvestedAmount

Returns the amount of lvlUSD tokens that are unvested in the contract.


```solidity
function getUnvestedAmount() public view returns (uint256);
```

### decimals

*Necessary because both ERC20 (from ERC20Permit) and ERC4626 declare decimals()*


```solidity
function decimals() public pure override(ERC4626, ERC20) returns (uint8);
```

### withdraw

*See [IERC4626-withdraw](/src/yield/AaveV3YieldManager.sol/contract.AaveV3YieldManager.md#withdraw).*


```solidity
function withdraw(uint256 assets, address receiver, address _owner)
    public
    virtual
    override
    ensureCooldownOff
    returns (uint256);
```

### redeem

*See [IERC4626-redeem](/src/LevelMinting.sol/contract.LevelMinting.md#redeem).*


```solidity
function redeem(uint256 shares, address receiver, address _owner)
    public
    virtual
    override
    ensureCooldownOff
    returns (uint256);
```

### _checkMinShares

ensures a small non-zero amount of shares does not remain, exposing to donation attack


```solidity
function _checkMinShares() internal view;
```

### _deposit

*Deposit/mint common workflow.*


```solidity
function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
    internal
    override
    nonReentrant
    notZero(assets)
    notZero(shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`caller`|`address`|sender of assets|
|`receiver`|`address`|where to send shares|
|`assets`|`uint256`|assets to deposit|
|`shares`|`uint256`|shares to mint|


### _withdraw

*Withdraw/redeem common workflow.*


```solidity
function _withdraw(address caller, address receiver, address _owner, uint256 assets, uint256 shares)
    internal
    override
    nonReentrant
    notZero(assets)
    notZero(shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`caller`|`address`|tx sender|
|`receiver`|`address`|where to send assets|
|`_owner`|`address`|where to burn shares from|
|`assets`|`uint256`|asset amount to transfer out|
|`shares`|`uint256`|shares to burn|


### _updateVestingAmount


```solidity
function _updateVestingAmount(uint256 newVestingAmount) internal;
```

### _beforeTokenTransfer

*Hook that is called before any transfer of tokens. This includes
minting and burning. Disables transfers from or to of addresses with the FULL_RESTRICTED_STAKER_ROLE role.*


```solidity
function _beforeTokenTransfer(address from, address to, uint256) internal virtual override;
```

### renounceRole

*Remove renounce role access from AccessControl, to prevent users to resign roles.*


```solidity
function renounceRole(bytes32, address) public virtual override;
```

