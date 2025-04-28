# ERC4626DelayedOracle
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v2/oracles/ERC4626DelayedOracle.sol)

**Inherits:**
[IERC4626Oracle](/src/v2/interfaces/level/IERC4626Oracle.sol/interface.IERC4626Oracle.md)


## State Variables
### vault

```solidity
IERC4626 public immutable vault;
```


### delay

```solidity
uint256 public immutable delay;
```


### decimals_

```solidity
uint8 public immutable decimals_;
```


### oneShare

```solidity
uint256 public immutable oneShare;
```


### price

```solidity
uint256 public price;
```


### nextPrice

```solidity
uint256 public nextPrice;
```


### updatedAt

```solidity
uint256 public updatedAt;
```


## Functions
### constructor


```solidity
constructor(IERC4626 _vault, uint256 _delay);
```

### update

Update the next price of the underlying ERC4626

*You can't call this function until the previous delay is exhausted*


```solidity
function update() public;
```

### decimals


```solidity
function decimals() external view returns (uint8);
```

### description


```solidity
function description() external pure returns (string memory);
```

### version


```solidity
function version() external pure returns (uint256);
```

### getRoundData


```solidity
function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80);
```

### latestRoundData


```solidity
function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
```

## Events
### Update

```solidity
event Update(uint256 updatedAt, uint256 prevPrice, uint256 currPrice, uint256 nextPrice);
```

