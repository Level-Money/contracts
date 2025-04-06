// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

uint256 constant WAD = 1e18;
uint256 constant MWEI = 1e6;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";

/// @title MathLib
/// @author Adapted from Morpho Labs (forked from https://github.com/morpho-org/morpho-blue/commit/cca006b3529ac04f2dcb5f8861067d485ae547b5)
/// @notice Library to manage fixed-point arithmetic.
library MathLib {
    /// @dev Returns (`x` * `y`) / `WAD` rounded down.
    function wMulDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD);
    }

    /// @dev Returns (`x` * `WAD`) / `y` rounded down.
    function wDivDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y);
    }

    /// @dev Returns (`x` * `WAD`) / `y` rounded up.
    function wDivUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y);
    }

    /// @dev Returns (`x` * `y`) / `d` rounded down.
    function mulDivDown(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y) / d;
    }

    /// @dev Returns (`x` * `y`) / `d` rounded up.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y + (d - 1)) / d;
    }

    /// @dev Returns the maximum of two numbers.
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /// @dev Returns the minimum of two numbers.
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    /// @dev Given an amount, a from ERC20, and a to ERC20, convert the amount from the from ERC20's decimals to the to ERC20's decimals and round down
    function convertDecimalsDown(uint256 amount, uint8 fromDecimals, uint8 toDecimals)
        internal
        pure
        returns (uint256)
    {
        return mulDivDown(amount, 10 ** (toDecimals), 10 ** (fromDecimals));
    }

    /// @dev Given an amount, a from ERC20, and a to ERC20, convert the amount from the from ERC20's decimals to the to ERC20's decimals and round up
    function convertDecimalsUp(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256) {
        return mulDivUp(amount, 10 ** (toDecimals), 10 ** (fromDecimals));
    }
}
