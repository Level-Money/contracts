// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {ERC4626Oracle} from "@level/src/v2/oracles/ERC4626Oracle.sol";
import {ERC4626DelayedOracle} from "@level/src/v2/oracles/ERC4626DelayedOracle.sol";

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
 * @title ERC4626OracleFactory
 * @author Level (https://level.money)
 * @notice Factory contract for ERC4626 Oracle and ERC4626 Delayed Oracle
 */
contract ERC4626OracleFactory {
    function create(IERC4626 vault) external returns (ERC4626Oracle) {
        ERC4626Oracle oracle = new ERC4626Oracle(vault);

        // Sanity checks
        if (oracle.decimals() != IERC20Metadata(vault.asset()).decimals()) {
            revert("Decimals mismatch");
        }

        (, int256 answer,,,) = oracle.latestRoundData();

        if (answer != int256(vault.convertToAssets(oracle.oneShare()))) {
            revert("Price mismatch");
        }

        return oracle;
    }

    function createDelayed(IERC4626 vault, uint256 delay) external returns (ERC4626DelayedOracle) {
        ERC4626DelayedOracle oracle = new ERC4626DelayedOracle(vault, delay);

        // Sanity checks
        if (oracle.decimals() != IERC20Metadata(vault.asset()).decimals()) {
            revert("Decimals mismatch");
        }

        (, int256 answer,,,) = oracle.latestRoundData();

        if (answer != int256(vault.convertToAssets(oracle.oneShare()))) {
            revert("Price mismatch");
        }

        return oracle;
    }
}
