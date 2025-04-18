# LevelBaseReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v1/reserve/LevelBaseReserveManager.sol)

**Inherits:**
[ILevelBaseReserveManager](/src/v1/interfaces/ILevelBaseReserveManager.sol/interface.ILevelBaseReserveManager.md), [SingleAdminAccessControl](/src/v1/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md), Pausable

This is the superclass for all reserve managers
to inherit common functionality. It is _not_ intended
to be deployed on its own.


## State Variables
### ALLOWLIST_ROLE
role that sets the addresses where funds can be sent from this contract


```solidity
bytes32 private constant ALLOWLIST_ROLE = keccak256("ALLOWLIST_ROLE");
```


### MANAGER_AGENT_ROLE
role that deposits to/withdraws from a yield strategy or a restaking protocol


```solidity
bytes32 internal constant MANAGER_AGENT_ROLE = keccak256("MANAGER_AGENT_ROLE");
```


### PAUSER_ROLE
role that pauses the contract


```solidity
bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
```


### treasury
address that receives the yield


```solidity
address public treasury;
```


### MAX_BASIS_POINTS
basis points of the max slippage threshold


```solidity
uint16 constant MAX_BASIS_POINTS = 1e4;
```


### rakeBasisPoints
basis points of the rake


```solidity
uint16 public rakeBasisPoints;
```


### MAX_RAKE_BASIS_POINTS

```solidity
uint16 public constant MAX_RAKE_BASIS_POINTS = 5000;
```


### maxSlippageThresholdBasisPoints
basis points of max slippage threshold


```solidity
uint16 public maxSlippageThresholdBasisPoints;
```


### lvlUSD

```solidity
IlvlUSD public immutable lvlUSD;
```


### lvlUsdDecimals

```solidity
uint256 public immutable lvlUsdDecimals;
```


### levelMinting

```solidity
ILevelMinting public immutable levelMinting;
```


### allowlist

```solidity
mapping(address => bool) public allowlist;
```


### stakedlvlUSD

```solidity
IStakedlvlUSD stakedlvlUSD;
```


### yieldManager

```solidity
mapping(address => ILevelBaseYieldManager) yieldManager;
```


## Functions
### constructor


```solidity
constructor(IlvlUSD _lvlUSD, IStakedlvlUSD _stakedlvlUSD, address _admin, address _allowlister);
```

### depositForYield

Convert `amount` of `token` to a yield bearing version
(ie wrapped Aave USDT if token is USDT)

*only callable by manager agent*


```solidity
function depositForYield(address token, uint256 amount) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|address of the token|
|`amount`|`uint256`|amount to deposit|


### withdrawFromYieldManager

Convert `amount` of `token` from a yield bearing version
(ie wrapped Aave USDT if token is USDT) to the native version (ie USDT)

*only callable by manager agent*


```solidity
function withdrawFromYieldManager(address token, uint256 amount) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|address of the token|
|`amount`|`uint256`|amount to withdraw|


### depositToLevelMinting

Deposit collateral to level minting contract, to be made available
for redemptions

*only callable by manager agent*


```solidity
function depositToLevelMinting(address token, uint256 amount) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|address of the collateral token|
|`amount`|`uint256`|amount of collateral to deposit|


### _takeRake

Take a rake from the amount and transfer it to the treasury


```solidity
function _takeRake(address token, uint256 amount) internal returns (uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|address of the token to take rake from|
|`amount`|`uint256`|amount of token to take rake from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|rake amount taken|
|`<none>`|`uint256`|remainder amount after rake|


### _rewardStakedlvlUSD

Rewards staked lvlUSD with lvlUSD. The admin should call
mint lvlUSD before calling this function

*only callable by admin*


```solidity
function _rewardStakedlvlUSD(uint256 amount) internal whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of lvlUSD to reward|


### _mintlvlUSD

Mint lvlUSD using collateral

*only callable by admin*


```solidity
function _mintlvlUSD(address collateral, uint256 collateralAmount) internal whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|address of the collateral token|
|`collateralAmount`|`uint256`|amount of collateral to mint lvlUSD with|


### rewardStakedlvlUSD


```solidity
function rewardStakedlvlUSD(address token) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused;
```

### approveSpender

Rescue functions- only callable by admin for emergencies

Approve spender to spend a certain amount of token

*only callable by admin*


```solidity
function approveSpender(address token, address spender, uint256 amount)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|address of the token|
|`spender`|`address`|address of the spender|
|`amount`|`uint256`|amount to approve|


### transferERC20

Transfer ERC20 token to a recipient

*only callable by admin*


```solidity
function transferERC20(address tokenAddress, address tokenReceiver, uint256 tokenAmount)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the token|
|`tokenReceiver`|`address`|address of the recipient|
|`tokenAmount`|`uint256`|amount of token to transfer|


### transferEth

Transfer ETH to a recipient

*only callable by admin*


```solidity
function transferEth(address payable _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address payable`|address of the recipient|
|`_amount`|`uint256`|amount of ETH to transfer|


### receive


```solidity
receive() external payable;
```

### fallback


```solidity
fallback() external payable;
```

### setPaused


```solidity
function setPaused(bool paused) external onlyRole(PAUSER_ROLE);
```

### setAllowlist


```solidity
function setAllowlist(address recipient, bool isAllowlisted) external onlyRole(ALLOWLIST_ROLE) whenNotPaused;
```

### setStakedlvlUSDAddress


```solidity
function setStakedlvlUSDAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setYieldManager


```solidity
function setYieldManager(address token, address baseYieldManager) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setTreasury


```solidity
function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setRakeBasisPoints


```solidity
function setRakeBasisPoints(uint16 _rakeBasisPoints) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setMaxSlippageThresholdBasisPoints


```solidity
function setMaxSlippageThresholdBasisPoints(uint16 _maxSlippageThresholdBasisPoints)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
```

## Events
### EtherReceived

```solidity
event EtherReceived(address indexed sender, uint256 amount);
```

### FallbackCalled

```solidity
event FallbackCalled(address indexed sender, uint256 amount, bytes data);
```

