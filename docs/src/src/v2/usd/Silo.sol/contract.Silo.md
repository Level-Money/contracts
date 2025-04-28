# Silo
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v2/usd/Silo.sol)


## State Variables
### owner

```solidity
address public immutable owner;
```


## Functions
### constructor


```solidity
constructor(address _owner);
```

### withdraw

only callable by LevelMintingV2


```solidity
function withdraw(address beneficiary, address asset, uint256 amount) external;
```

