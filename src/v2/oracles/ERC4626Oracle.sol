// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
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
 * @title ERC4626Oracle
 * @author Level (https://level.money)
 * @notice Oracle contract for ERC4626 vaults. Returns the current `convertToAssets` value of a vault share
 */
contract ERC4626Oracle is IERC4626Oracle {
    IERC4626 public immutable vault;

    uint8 public immutable decimals_;
    uint256 public immutable oneShare;

    constructor(IERC4626 _vault) {
        vault = _vault;

        decimals_ = IERC20Metadata(vault.asset()).decimals();
        oneShare = 10 ** vault.decimals();
    }

    function update() external {}

    function decimals() external view returns (uint8) {
        return decimals_;
    }

    function description() external pure returns (string memory) {
        return "Chainlink-compliant ERC4626 Oracle";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 /*_roundId */ ) external view returns (uint80, int256, uint256, uint256, uint80) {
        return this.latestRoundData();
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        uint256 price = vault.convertToAssets(oneShare);
        return (0, int256(price), block.timestamp, block.timestamp, 0);
    }
}
