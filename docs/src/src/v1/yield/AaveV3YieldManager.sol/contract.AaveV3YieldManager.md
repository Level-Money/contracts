# AaveV3YieldManager
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/yield/AaveV3YieldManager.sol)

**Inherits:**
[BaseYieldManager](/src/v1/yield/BaseYieldManager.sol/abstract.BaseYieldManager.md)

This contract serves as middleware to wrap native tokens into ERC20
wrapped aTokens


## State Variables
### aavePoolProxy

```solidity
IPool public aavePoolProxy;
```


### aTokenToUnderlying

```solidity
mapping(address => address) public aTokenToUnderlying;
```


### underlyingToaToken

```solidity
mapping(address => address) public underlyingToaToken;
```


### tokenToWrapper

```solidity
mapping(address => address) public tokenToWrapper;
```


## Functions
### constructor


```solidity
constructor(IPool _aavePoolProxy, address _admin) BaseYieldManager(_admin);
```

### _wrapToken


```solidity
function _wrapToken(address token, uint256 amount) internal;
```

### _unwrapToken


```solidity
function _unwrapToken(address wrapper, uint256 amount) internal;
```

### _withdrawFromAave


```solidity
function _withdrawFromAave(address token, uint256 amount) internal;
```

### _depositToAave


```solidity
function _depositToAave(address token, uint256 amount) internal;
```

### _getATokenAddress


```solidity
function _getATokenAddress(address underlying) internal returns (address);
```

### depositForYield


```solidity
function depositForYield(address token, uint256 amount) external;
```

### withdraw


```solidity
function withdraw(address token, uint256 amount) external;
```

### collectYield


```solidity
function collectYield(address token) external onlyRole(YIELD_RECOVERER_ROLE) returns (uint256);
```

### setAaveV3PoolAddress


```solidity
function setAaveV3PoolAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setWrapperForToken


```solidity
function setWrapperForToken(address token, address wrapper) external onlyRole(DEFAULT_ADMIN_ROLE);
```

## Events
### DepositedToAave

```solidity
event DepositedToAave(uint256 amount, address token);
```

### WithdrawnFromAave

```solidity
event WithdrawnFromAave(uint256 amount, address token);
```

## Errors
### TokenERC20WrapperNotSet

```solidity
error TokenERC20WrapperNotSet();
```

### InvalidWrapper

```solidity
error InvalidWrapper();
```

### TokenAndWrapperDecimalsMismatch

```solidity
error TokenAndWrapperDecimalsMismatch();
```

### ZeroYieldToWithdraw

```solidity
error ZeroYieldToWithdraw();
```

