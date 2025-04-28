# ERC4626OracleFactory
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v2/oracles/ERC4626OracleFactory.sol)


## Functions
### create


```solidity
function create(IERC4626 vault) external returns (ERC4626Oracle);
```

### createDelayed


```solidity
function createDelayed(IERC4626 vault, uint256 delay) external returns (ERC4626DelayedOracle);
```

