# IKarakReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v1/interfaces/ILevelKarakReserveManager.sol)


## Functions
### depositToKarak


```solidity
function depositToKarak(address vault, uint256 amount) external returns (uint256 shares);
```

### startRedeemFromKarak


```solidity
function startRedeemFromKarak(address vault, uint256 shares) external returns (bytes32 withdrawalKey);
```

### finishRedeemFromKarak


```solidity
function finishRedeemFromKarak(address vault, bytes32 withdrawalKey) external;
```

## Events
### DepositedToKarak

```solidity
event DepositedToKarak(uint256 amount, address karakVault);
```

### RedeemFromKarakStarted

```solidity
event RedeemFromKarakStarted(uint256 shares, address karakVault, bytes32 withdrawalKey);
```

### RedeemFromKarakFinished

```solidity
event RedeemFromKarakFinished(address karakVault, bytes32 withdrawalKey);
```

