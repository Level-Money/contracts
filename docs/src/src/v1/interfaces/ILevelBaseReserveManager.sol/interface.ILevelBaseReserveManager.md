# ILevelBaseReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/interfaces/ILevelBaseReserveManager.sol)


## Functions
### treasury


```solidity
function treasury() external view returns (address);
```

### rakeBasisPoints


```solidity
function rakeBasisPoints() external view returns (uint16);
```

### maxSlippageThresholdBasisPoints


```solidity
function maxSlippageThresholdBasisPoints() external view returns (uint16);
```

### lvlUSD


```solidity
function lvlUSD() external view returns (IlvlUSD);
```

### lvlUsdDecimals


```solidity
function lvlUsdDecimals() external view returns (uint256);
```

### levelMinting


```solidity
function levelMinting() external view returns (ILevelMinting);
```

### allowlist


```solidity
function allowlist(address) external view returns (bool);
```

### depositForYield


```solidity
function depositForYield(address token, uint256 amount) external;
```

### withdrawFromYieldManager


```solidity
function withdrawFromYieldManager(address token, uint256 amount) external;
```

### depositToLevelMinting


```solidity
function depositToLevelMinting(address token, uint256 amount) external;
```

### approveSpender


```solidity
function approveSpender(address token, address spender, uint256 amount) external;
```

### transferERC20


```solidity
function transferERC20(address tokenAddress, address tokenReceiver, uint256 tokenAmount) external;
```

### transferEth


```solidity
function transferEth(address payable _to, uint256 _amount) external;
```

### setPaused


```solidity
function setPaused(bool paused) external;
```

### setAllowlist


```solidity
function setAllowlist(address recipient, bool isAllowlisted) external;
```

### setStakedlvlUSDAddress


```solidity
function setStakedlvlUSDAddress(address newAddress) external;
```

### setYieldManager


```solidity
function setYieldManager(address token, address baseYieldManager) external;
```

### setTreasury


```solidity
function setTreasury(address _treasury) external;
```

### setRakeBasisPoints


```solidity
function setRakeBasisPoints(uint16 _rakeBasisPoints) external;
```

### setMaxSlippageThresholdBasisPoints


```solidity
function setMaxSlippageThresholdBasisPoints(uint16 _maxSlippageThresholdBasisPoints) external;
```

## Events
### DepositedToYieldManager

```solidity
event DepositedToYieldManager(address token, address yieldManager, uint256 amount);
```

### WithdrawnFromYieldManager

```solidity
event WithdrawnFromYieldManager(address token, address yieldManager, uint256 amount);
```

### DepositedToLevelMinting

```solidity
event DepositedToLevelMinting(uint256 amount);
```

### YieldManagerSetForToken

```solidity
event YieldManagerSetForToken(address token, address yieldManager);
```

## Errors
### InvalidlvlUSDAddress

```solidity
error InvalidlvlUSDAddress();
```

### InvalidZeroAddress

```solidity
error InvalidZeroAddress();
```

### TreasuryNotSet

```solidity
error TreasuryNotSet();
```

### InvalidAmount

```solidity
error InvalidAmount();
```

### InvalidRecipient

```solidity
error InvalidRecipient();
```

