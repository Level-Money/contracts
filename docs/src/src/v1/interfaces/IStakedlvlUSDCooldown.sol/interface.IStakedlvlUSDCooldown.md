# IStakedlvlUSDCooldown
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v1/interfaces/IStakedlvlUSDCooldown.sol)

**Inherits:**
[IStakedlvlUSD](/src/v1/interfaces/IStakedlvlUSD.sol/interface.IStakedlvlUSD.md)


## Functions
### cooldownAssets


```solidity
function cooldownAssets(uint256 assets) external returns (uint256 shares);
```

### cooldownShares


```solidity
function cooldownShares(uint256 shares) external returns (uint256 assets);
```

### unstake


```solidity
function unstake(address receiver) external;
```

### setCooldownDuration


```solidity
function setCooldownDuration(uint24 duration) external;
```

## Events
### CooldownDurationUpdated
Event emitted when cooldown duration updates


```solidity
event CooldownDurationUpdated(uint24 previousDuration, uint24 newDuration);
```

### SiloUpdated
Event emitted when the silo address updates


```solidity
event SiloUpdated(address previousSilo, address newSilo);
```

## Errors
### ExcessiveRedeemAmount
Error emitted when the shares amount to redeem is greater than the shares balance of the owner


```solidity
error ExcessiveRedeemAmount();
```

### ExcessiveWithdrawAmount
Error emitted when the shares amount to withdraw is greater than the shares balance of the owner


```solidity
error ExcessiveWithdrawAmount();
```

### InvalidCooldown
Error emitted when cooldown value is invalid


```solidity
error InvalidCooldown();
```

