// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IUniswapV3Pool} from "@uniswap-v3-core/interfaces/IUniswapV3Pool.sol";
import {ISwapRouter} from "@level/src/v2/interfaces/uniswap/ISwapRouter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {SwapManagerStorage} from "./SwapManagerStorage.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";
import {SwapConfig} from "./SwapManagerStorage.sol";
import {PauserGuardedUpgradable} from "@level/src/v2/common/guard/PauserGuardedUpgradable.sol";
import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

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
contract SwapManager is SwapManagerStorage, Initializable, UUPSUpgradeable, AuthUpgradeable, PauserGuardedUpgradable {
    /// @notice Constructor that disables initializers
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with admin and swap router addresses
    /// @param admin_ The address of the admin who can manage the contract
    /// @param swapRouter_ The address of the Uniswap V3 Swap Router
    /// @param guard_ The address of the guard that controls the pause state of the contract
    function initialize(address admin_, address swapRouter_, address guard_) external initializer {
        __UUPSUpgradeable_init();
        __Auth_init(admin_, address(0));
        __PauserGuarded_init(guard_);
        swapRouter = ISwapRouter(swapRouter_);
    }

    /// @notice Sets the swap configuration for a token pair
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param config The swap configuration parameters
    /// @dev Only callable by authorized addresses
    function setSwapConfig(address tokenIn, address tokenOut, SwapConfig memory config)
        external
        requiresAuth
        notPaused
    {
        // add access control here
        require(config.pool != address(0), "Invalid pool");
        swapConfigs[tokenIn][tokenOut] = config;
    }

    /// @notice Adds an oracle to the swap manager
    /// @param token The address of the token to add an oracle for
    /// @param oracle The address of the oracle to add
    /// @dev Only callable by authorized addresses
    function addOracle(address token, address oracle) public requiresAuth {
        oracles[token] = oracle;
    }

    /// @notice Sets the heart beat for a token
    /// @param token The address of the token to set the heart beat for
    /// @param heartBeat The heart beat to set
    /// @dev Only callable by authorized addresses
    function setHeartBeat(address token, uint256 heartBeat) public requiresAuth {
        heartbeats[token] = heartBeat;
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
        notPaused
        returns (uint256 amountOut)
    {
        SwapConfig memory config = swapConfigs[tokenIn][tokenOut];
        require(config.active, "Swap not enabled");

        // Check tick range
        (, int24 currentTick,,,,,) = IUniswapV3Pool(config.pool).slot0();
        require(currentTick >= config.tickLower && currentTick <= config.tickUpper, "SwapManager: Out of tick range");

        uint128 liquidity = IUniswapV3Pool(config.pool).liquidity();
        require(liquidity > 0, "SwapManager: No liquidity");

        IERC20Metadata tokenInMetadata = IERC20Metadata(tokenIn);
        IERC20Metadata tokenOutMetadata = IERC20Metadata(tokenOut);

        // Transfer & approve
        tokenInMetadata.transferFrom(msg.sender, address(this), amountIn);
        tokenInMetadata.approve(address(swapRouter), amountIn);

        (int256 inputTokenPrice, uint256 inputPriceDecimals) =
            OracleLib.getPriceAndDecimals(oracles[tokenIn], heartbeats[tokenIn]);

        (int256 outputTokenPrice, uint256 outputPriceDecimals) =
            OracleLib.getPriceAndDecimals(oracles[tokenOut], heartbeats[tokenOut]);

        require(inputTokenPrice > 0 && outputTokenPrice > 0, "SwapManager: Invalid oracle price");

        uint8 tokenInDecimals = tokenInMetadata.decimals();
        uint8 tokenOutDecimals = tokenOutMetadata.decimals();

        // Normalize amountIn to 1e18
        uint256 amountInNormalized = Math.mulDiv(amountIn, 1e18, 10 ** tokenInDecimals);

        // Normalize oracle prices to 1e18
        uint256 inputPriceNormalized = Math.mulDiv(uint256(inputTokenPrice), 1e18, 10 ** inputPriceDecimals);
        uint256 outputPriceNormalized = Math.mulDiv(uint256(outputTokenPrice), 1e18, 10 ** outputPriceDecimals);

        // Calculate expected output amount (in 1e18 units)
        uint256 expectedOutNormalized = (amountInNormalized * inputPriceNormalized) / outputPriceNormalized;

        // Scale expectedOut back to tokenOut decimals
        uint256 adjustedOutAmount = Math.mulDiv(expectedOutNormalized, 10 ** tokenOutDecimals, 1e18);

        // Calculate slippage min out
        uint256 minOut = (adjustedOutAmount * (10_000 - config.slippageBps) + 10_000 - 1) / 10_000; // Round up

        // Build params
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: config.fee,
            recipient: recipient,
            deadline: block.timestamp,
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
