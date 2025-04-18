# Silo
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v2/usd/Silo.sol)


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

