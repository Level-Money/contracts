# MathLib
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/common/libraries/MathLib.sol)

**Author:**
Adapted from Morpho Labs (forked from https://github.com/morpho-org/morpho-blue/commit/cca006b3529ac04f2dcb5f8861067d485ae547b5)

Library to manage fixed-point arithmetic.


## Functions
### wMulDown

*Returns (`x` * `y`) / `WAD` rounded down.*


```solidity
function wMulDown(uint256 x, uint256 y) internal pure returns (uint256);
```

### wDivDown

*Returns (`x` * `WAD`) / `y` rounded down.*


```solidity
function wDivDown(uint256 x, uint256 y) internal pure returns (uint256);
```

### wDivUp

*Returns (`x` * `WAD`) / `y` rounded up.*


```solidity
function wDivUp(uint256 x, uint256 y) internal pure returns (uint256);
```

### mulDivDown

*Returns (`x` * `y`) / `d` rounded down.*


```solidity
function mulDivDown(uint256 x, uint256 y, uint256 d) internal pure returns (uint256);
```

### mulDivUp

*Returns (`x` * `y`) / `d` rounded up.*


```solidity
function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256);
```

### max

*Returns the maximum of two numbers.*


```solidity
function max(uint256 x, uint256 y) internal pure returns (uint256);
```

### min

*Returns the minimum of two numbers.*


```solidity
function min(uint256 x, uint256 y) internal pure returns (uint256);
```

### convertDecimalsDown

*Given an amount, a from ERC20, and a to ERC20, convert the amount from the from ERC20's decimals to the to ERC20's decimals and round down*


```solidity
function convertDecimalsDown(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256);
```

### convertDecimalsUp

*Given an amount, a from ERC20, and a to ERC20, convert the amount from the from ERC20's decimals to the to ERC20's decimals and round up*


```solidity
function convertDecimalsUp(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256);
```

