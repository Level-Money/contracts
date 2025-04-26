# ERC4626OracleFactory
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/oracles/ERC4626OracleFactory.sol)


## Functions
### create


```solidity
function create(IERC4626 vault) external returns (ERC4626Oracle);
```

### createDelayed


```solidity
function createDelayed(IERC4626 vault, uint256 delay) external returns (ERC4626DelayedOracle);
```

