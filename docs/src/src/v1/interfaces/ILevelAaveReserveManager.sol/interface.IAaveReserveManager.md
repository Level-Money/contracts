# IAaveReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v1/interfaces/ILevelAaveReserveManager.sol)


## Functions
### depositToAave


```solidity
function depositToAave(address token, uint256 amount) external;
```

### withdrawFromAave


```solidity
function withdrawFromAave(address token, uint256 amount) external;
```

### convertATokentolvlUSD


```solidity
function convertATokentolvlUSD(address token, uint256 amount) external returns (uint256);
```

### setAaveV3PoolAddress


```solidity
function setAaveV3PoolAddress(address newAddress) external;
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

