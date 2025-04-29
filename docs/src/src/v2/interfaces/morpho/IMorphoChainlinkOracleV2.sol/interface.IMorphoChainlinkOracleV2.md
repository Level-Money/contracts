# IMorphoChainlinkOracleV2
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/interfaces/morpho/IMorphoChainlinkOracleV2.sol)

**Author:**
Morpho Labs

Interface of MorphoChainlinkOracleV2.

**Note:**
contact: security@morpho.org


## Functions
### BASE_VAULT

Returns the address of the base ERC4626 vault.


```solidity
function BASE_VAULT() external view returns (IERC4626);
```

### BASE_VAULT_CONVERSION_SAMPLE

Returns the base vault conversion sample.


```solidity
function BASE_VAULT_CONVERSION_SAMPLE() external view returns (uint256);
```

### QUOTE_VAULT

Returns the address of the quote ERC4626 vault.


```solidity
function QUOTE_VAULT() external view returns (IERC4626);
```

### QUOTE_VAULT_CONVERSION_SAMPLE

Returns the quote vault conversion sample.


```solidity
function QUOTE_VAULT_CONVERSION_SAMPLE() external view returns (uint256);
```

### BASE_FEED_1

Returns the address of the first base feed.


```solidity
function BASE_FEED_1() external view returns (AggregatorV3Interface);
```

### BASE_FEED_2

Returns the address of the second base feed.


```solidity
function BASE_FEED_2() external view returns (AggregatorV3Interface);
```

### QUOTE_FEED_1

Returns the address of the first quote feed.


```solidity
function QUOTE_FEED_1() external view returns (AggregatorV3Interface);
```

### QUOTE_FEED_2

Returns the address of the second quote feed.


```solidity
function QUOTE_FEED_2() external view returns (AggregatorV3Interface);
```

### SCALE_FACTOR

Returns the price scale factor, calculated at contract creation.


```solidity
function SCALE_FACTOR() external view returns (uint256);
```

### price


```solidity
function price() external view returns (uint256);
```

