# ILevelBaseYieldManager
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/interfaces/ILevelBaseYieldManager.sol)


## Functions
### setWrapperForToken


```solidity
function setWrapperForToken(address token, address wrapper) external;
```

### approveSpender


```solidity
function approveSpender(address token, address spender, uint256 amount) external;
```

### depositForYield


```solidity
function depositForYield(address token, uint256 amount) external;
```

### collectYield


```solidity
function collectYield(address token) external returns (uint256);
```

### withdraw


```solidity
function withdraw(address token, uint256 amount) external;
```

## Errors
### TreasuryNotSet
Treasury is the zero address


```solidity
error TreasuryNotSet();
```

### ZeroAddress
Zero address error


```solidity
error ZeroAddress();
```

