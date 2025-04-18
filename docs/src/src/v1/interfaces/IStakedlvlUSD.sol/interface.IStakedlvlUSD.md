# IStakedlvlUSD
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v1/interfaces/IStakedlvlUSD.sol)


## Functions
### transferInRewards


```solidity
function transferInRewards(uint256 amount) external;
```

### rescueTokens


```solidity
function rescueTokens(address token, uint256 amount, address to) external;
```

### getUnvestedAmount


```solidity
function getUnvestedAmount() external view returns (uint256);
```

## Events
### RewardsReceived
Event emitted when the rewards are received


```solidity
event RewardsReceived(uint256 indexed amount);
```

### FrozenFundsReceived
Event emitted when frozen funds are received


```solidity
event FrozenFundsReceived(uint256 indexed amount);
```

### LockedAmountRedistributed
Event emitted when the balance from an FULL_RESTRICTED_STAKER_ROLE user are redistributed


```solidity
event LockedAmountRedistributed(address indexed from, address indexed to, uint256 amount);
```

### FrozenAmountUpdated
Event emitted when a FREEZER_ROLE user freezes an amount of the reserve


```solidity
event FrozenAmountUpdated(uint256 amount);
```

### FrozenAmountWithdrawn

```solidity
event FrozenAmountWithdrawn(address indexed frozenReceiver, uint256 amount);
```

### FrozenReceiverSet

```solidity
event FrozenReceiverSet(address indexed oldReceiver, address indexed newReceiver);
```

### FrozenReceiverSettingRenounced

```solidity
event FrozenReceiverSettingRenounced();
```

### FreezablePercentageUpdated

```solidity
event FreezablePercentageUpdated(uint16 oldFreezablePercentage, uint16 newFreezablePercentage);
```

## Errors
### InvalidAmount
Error emitted shares or assets equal zero.


```solidity
error InvalidAmount();
```

### InvalidToken
Error emitted when owner attempts to rescue lvlUSD tokens.


```solidity
error InvalidToken();
```

### SlippageExceeded
Error emitted when slippage is exceeded on a deposit or withdrawal


```solidity
error SlippageExceeded();
```

### MinSharesViolation
Error emitted when a small non-zero share amount remains, which risks donations attack


```solidity
error MinSharesViolation();
```

### OperationNotAllowed
Error emitted when owner is not allowed to perform an operation


```solidity
error OperationNotAllowed();
```

### StillVesting
Error emitted when there is still unvested amount


```solidity
error StillVesting();
```

### CantDenylistOwner
Error emitted when owner or denylist manager attempts to denylist owner


```solidity
error CantDenylistOwner();
```

### InvalidZeroAddress
Error emitted when the zero address is given


```solidity
error InvalidZeroAddress();
```

### InsufficientBalance
Error emitted when there is not enough balance


```solidity
error InsufficientBalance();
```

### SettingFrozenReceiverDisabled
Error emitted when the caller cannot set a freezer


```solidity
error SettingFrozenReceiverDisabled();
```

### ExceedsFreezable
Error emitted when trying to freeze more than max freezable


```solidity
error ExceedsFreezable();
```

