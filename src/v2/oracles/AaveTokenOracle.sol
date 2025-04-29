// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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
 * @title AaveTokenOracle
 * @author Level (https://level.money)
 * @notice Oracle contract for Aave receipt tokens. Hard-codes a price 1:1
 */
contract AaveTokenOracle is AggregatorV3Interface {
    IERC20Metadata public immutable underlying;

    constructor(address _underlying) {
        underlying = IERC20Metadata(_underlying);
    }

    function decimals() external view returns (uint8) {
        return underlying.decimals();
    }

    function description() external pure returns (string memory) {
        return "Chainlink-compliant Aave Token Oracle";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 /*_roundId */ ) external view returns (uint80, int256, uint256, uint256, uint80) {
        return this.latestRoundData();
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, int256(10 ** underlying.decimals()), block.timestamp, block.timestamp, 0);
    }
}
