// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISwapRouter} from "@level/src/v2/interfaces/uniswap/ISwapRouter.sol";

/**
 * @title SwapConfig
 * @notice Configuration structure for managing swap parameters
 * @dev Contains all necessary parameters for configuring a swap pool and its behavior
 */
struct SwapConfig {
    /// @notice The address of the Uniswap V3 pool
    address pool;
    /// @notice The fee tier of the pool in hundredths of a basis point (e.g., 3000 = 0.3%)
    uint24 fee;
    /// @notice The lower tick boundary for the position
    int24 tickLower;
    /// @notice The upper tick boundary for the position
    int24 tickUpper;
    /// @notice The maximum allowed slippage in basis points (e.g., 10 = 0.1%)
    uint256 slippageBps;
    /// @notice Whether this swap configuration is currently active
    bool active;
}

/**
 * @title SwapManagerStorage
 * @notice Storage contract for managing swap configurations and router interactions
 * @dev This contract stores the swap router and configurations for different token pairs
 * @dev Inherits from OpenZeppelin's storage gap pattern for upgradeability
 */
abstract contract SwapManagerStorage {
    /// @notice The Uniswap V3 SwapRouter contract instance
    ISwapRouter public swapRouter;

    /// @notice Mapping of token pairs to their swap configurations
    /// @dev First address is token0, second address is token1
    mapping(address => mapping(address => SwapConfig)) public swapConfigs;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
