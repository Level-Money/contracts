# ISymbioticReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/interfaces/ILevelSymbioticReserveManager.sol)


## Functions
### depositToSymbiotic


```solidity
function depositToSymbiotic(address vault, uint256 amount)
    external
    returns (uint256 depositedAmount, uint256 mintedShares);
```

### withdrawFromSymbiotic


```solidity
function withdrawFromSymbiotic(address vault, uint256 amount)
    external
    returns (uint256 burnedShares, uint256 mintedShares);
```

### claimFromSymbiotic


```solidity
function claimFromSymbiotic(address vault, uint256 epoch) external returns (uint256 amount);
```

## Events
### DepositedToSymbiotic

```solidity
event DepositedToSymbiotic(uint256 amount, address symbioticVault);
```

### WithdrawnFromSymbiotic

```solidity
event WithdrawnFromSymbiotic(uint256 amount, address symbioticVault);
```

### ClaimedFromSymbiotic

```solidity
event ClaimedFromSymbiotic(uint256 epoch, uint256 amount, address symbioticVault);
```

