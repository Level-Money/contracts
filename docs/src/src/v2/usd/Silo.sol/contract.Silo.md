# Silo
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/usd/Silo.sol)


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

