// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

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
 * @title Silo
 * @author Level (https://level.money)
 * @notice Contract for storing assets during cooldown for LevelMintingV2
 * @dev Callable by LevelMintingV2, which is the deployer
 */
contract Silo {
    using SafeTransferLib for ERC20;

    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /// @notice only callable by LevelMintingV2
    function withdraw(address beneficiary, address asset, uint256 amount) external {
        require(msg.sender == owner, "Unauthorized");
        require(asset.code.length != 0, "Token does not exist");
        ERC20(asset).safeTransfer(beneficiary, amount);
    }
}
