// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";

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
 * @title CappedOneDollarOracle
 * @author Level (https://level.money)
 * @notice Oracle that returns the lower of 1 dollar or the price from another oracle
 */
contract CappedOneDollarOracle is AggregatorV3Interface {
    error InvalidExternalOracle();

    uint8 public immutable decimals;
    AggregatorV3Interface public immutable externalOracle;

    constructor(address _externalOracle) {
        if (_externalOracle == address(0)) revert InvalidExternalOracle();
        externalOracle = AggregatorV3Interface(_externalOracle);
        decimals = externalOracle.decimals();
    }

    function description() external pure override returns (string memory) {
        return "Capped $1 Oracle with fallback";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = externalOracle.getRoundData(_roundId);

        // Cap the price at $1.00 (10 ** decimals)
        int256 capped = answer < int256(10 ** decimals) ? answer : int256(10 ** decimals);

        return (roundId, capped, startedAt, updatedAt, answeredInRound);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (uint80 extRoundId, int256 extAnswer, uint256 extStartedAt, uint256 extUpdatedAt, uint80 extAnsweredInRound) =
            externalOracle.latestRoundData();

        // Cap the price at $1.00 (10 ** decimals)
        int256 capped = extAnswer < int256(10 ** decimals) ? extAnswer : int256(10 ** decimals);

        return (extRoundId, capped, extStartedAt, extUpdatedAt, extAnsweredInRound);
    }
}
