# Silo
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/usd/Silo.sol)


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

