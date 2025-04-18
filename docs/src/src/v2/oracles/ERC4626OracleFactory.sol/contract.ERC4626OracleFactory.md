# ERC4626OracleFactory
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/oracles/ERC4626OracleFactory.sol)


## Functions
### create


```solidity
function create(IERC4626 vault) external returns (ERC4626Oracle);
```

### createDelayed


```solidity
function createDelayed(IERC4626 vault, uint256 delay) external returns (ERC4626DelayedOracle);
```

