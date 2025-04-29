// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IRewardsManager} from "@level/src/v2/interfaces/level/IRewardsManager.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";

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
 * @title RewardsManagerStorage
 * @author Level (https://level.money)
 * @notice Storage contract for RewardsManager. Separate to make it easier to discern upgrades.
 * @dev Inherits interface from IRewardsManager
 */
abstract contract RewardsManagerStorage is IRewardsManager {
    BoringVault public vault;

    address public treasury;

    mapping(address => StrategyConfig[]) public allStrategies;
    mapping(address => address) public oracles;

    address[] public allBaseCollateral;

    uint256 public constant HEARTBEAT = 1 days;

    constructor() {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
