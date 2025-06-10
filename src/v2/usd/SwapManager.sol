// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IUniswapV3Pool} from "@uniswap-v3-core/interfaces/IUniswapV3Pool.sol";
import {ISwapRouter} from "@level/src/v2/interfaces/uniswap/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SwapManagerStorage} from "./SwapManagerStorage.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";
import {SwapConfig} from "./SwapManagerStorage.sol";

/**
 *                                     .-==+=======+:
 *                                      :---=-::-==:
 *                                      .-:-==-:-==:
 *                    .:::--::::::.     .--:-=--:--.       .:--:::--..
 *                   .=++=++:::::..     .:::---::--.    ....::...:::.
 *                    :::-::..::..      .::::-:::::.     ...::...:::.
 *                    ...::..::::..     .::::--::-:.    ....::...:::..
 *                    ............      ....:::..::.    ------:......
 *    ...........     ........:....     .....::..:..    ======-......      ...........
 *    :------:.:...   ...:+***++*#+     .------:---.    ...::::.:::...   .....:-----::.
 *    .::::::::-:..   .::--..:-::..    .-=+===++=-==:   ...:::..:--:..   .:==+=++++++*:
 *
 * @title SwapManager
 * @author Level (https://level.money)
 * @notice Manages token swaps using Uniswap V3 pools with configurable parameters
 * @dev This contract is upgradeable and uses UUPS pattern
 */
contract SwapManager is SwapManagerStorage, Initializable, UUPSUpgradeable, AuthUpgradeable {
    /// @notice Constructor that disables initializers
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with admin and swap router addresses
    /// @param admin_ The address of the admin who can manage the contract
    /// @param swapRouter_ The address of the Uniswap V3 Swap Router
    function initialize(address admin_, address swapRouter_) external initializer {
        __UUPSUpgradeable_init();
        __Auth_init(admin_, address(0));
        swapRouter = ISwapRouter(swapRouter_);
    }

    /// @notice Sets the swap configuration for a token pair
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param config The swap configuration parameters
    /// @dev Only callable by authorized addresses
    function setSwapConfig(address tokenIn, address tokenOut, SwapConfig memory config) external requiresAuth {
        // add access control here
        require(config.pool != address(0), "Invalid pool");
        swapConfigs[tokenIn][tokenOut] = config;
    }

    /// @notice Executes a token swap using the configured parameters
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The amount of input tokens to swap
    /// @param recipient The address that will receive the output tokens
    /// @return amountOut The amount of output tokens received
    /// @dev Checks tick range and liquidity before executing swap
    ///
    /// @dev In order to enforce checks on the amount of token coming out,
    /// use the slippage in the pair's swap config.
    function swap(address tokenIn, address tokenOut, uint256 amountIn, address recipient)
        external
        returns (uint256 amountOut)
    {
        SwapConfig memory config = swapConfigs[tokenIn][tokenOut];
        require(config.active, "Swap not enabled");

        // Check tick range
        (, int24 currentTick,,,,,) = IUniswapV3Pool(config.pool).slot0();
        require(currentTick >= config.tickLower && currentTick <= config.tickUpper, "SwapManager: Out of tick range");

        uint128 liquidity = IUniswapV3Pool(config.pool).liquidity();
        require(liquidity > 0, "SwapManager: No liquidity");

        // Transfer & approve
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // Calculate slippage min out
        uint256 minOut = (amountIn * (10_000 - config.slippageBps)) / 10_000;

        // Build params
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: config.fee,
            recipient: recipient,
            deadline: block.timestamp + 60,
            amountIn: amountIn,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
    }

    // ------- Upgradeable ---------

    /// @notice Authorizes an upgrade to a new implementation
    /// @param newImplementation The address of the new implementation
    /// @dev Only callable by authorized addresses
    function _authorizeUpgrade(address newImplementation) internal override requiresAuth {}
}
