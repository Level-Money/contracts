# ERC4626OracleFactory
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/oracles/ERC4626OracleFactory.sol)


## Functions
### create


```solidity
function create(IERC4626 vault) external returns (ERC4626Oracle);
```

### createDelayed


```solidity
function createDelayed(IERC4626 vault, uint256 delay) external returns (ERC4626DelayedOracle);
```

