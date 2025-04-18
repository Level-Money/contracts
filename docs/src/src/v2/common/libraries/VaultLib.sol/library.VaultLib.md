# VaultLib
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/common/libraries/VaultLib.sol)


## State Variables
### AAVE_V3_POOL_ADDRESSES_PROVIDER

```solidity
address public constant AAVE_V3_POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
```


## Functions
### _getTotalAssets


```solidity
function _getTotalAssets(BoringVault vault, StrategyConfig[] memory strategies, address asset)
    internal
    view
    returns (uint256 total);
```

### _withdrawBatch


```solidity
function _withdrawBatch(BoringVault vault, StrategyConfig[] memory strategies, uint256 amount)
    internal
    returns (uint256 withdrawn);
```

### _deposit


```solidity
function _deposit(BoringVault vault, StrategyConfig memory config, uint256 amount)
    internal
    returns (uint256 deposited);
```

### _withdraw


```solidity
function _withdraw(BoringVault vault, StrategyConfig memory config, uint256 amount)
    internal
    returns (uint256 withdrawn);
```

### _depositToAave

*aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.*


```solidity
function _depositToAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 deposited);
```

### _withdrawFromAave

*aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.*


```solidity
function _withdrawFromAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 withdrawn);
```

### _getAaveV3Pool


```solidity
function _getAaveV3Pool() internal view returns (address);
```

### _depositToMorpho


```solidity
function _depositToMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 deposited);
```

### _withdrawFromMorpho


```solidity
function _withdrawFromMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
    internal
    returns (uint256 withdrawn);
```

## Events
### DepositToAave

```solidity
event DepositToAave(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);
```

### WithdrawFromAave

```solidity
event WithdrawFromAave(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);
```

### DepositToMorpho

```solidity
event DepositToMorpho(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);
```

### WithdrawFromMorpho

```solidity
event WithdrawFromMorpho(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);
```

