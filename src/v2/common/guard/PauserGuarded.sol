// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";

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
 * @title PauserGuarded
 * @notice An abstract controller that uses a PauserGuard
 * to control the pause state of the inheriting contract.
 *
 * @dev This contract is used to control the pause state of the contract.
 */
abstract contract PauserGuarded {
    event PauserGuardUpdated(address indexed oldGuard, address indexed newGuard);

    error Paused();

    // @dev The guard that controls the pause state of the contract.
    PauserGuard public guard;

    /**
     * @dev Constructor to initialize the PauserGuard.
     * @param _guard The address of the PauserGuard to use.
     */
    constructor(address _guard) {
        if (_guard == address(0)) {
            revert("Guard cannot be zero address");
        }
        guard = PauserGuard(_guard);
    }

    /**
     * @dev Modifier to check if the contract is paused.
     * @dev Throws if the contract is paused.
     */
    modifier notPaused() {
        if (isPaused(address(this), msg.sig)) {
            revert Paused();
        }
        _;
    }

    /**
     * @dev Returns true if the contract is paused.
     * @param selector The selector of the function to check.
     * @return True if the contract is paused, false otherwise.
     */
    function isPaused(address target, bytes4 selector) internal view returns (bool) {
        return guard.isPaused(target, selector);
    }

    /**
     * @dev Contracts that call this function should implement this function with their own access control
     * @custom:auditnote is there anyway to throw a warning or an error if this function is not called by a child contract?
     */
    function _setGuard(address _guard) internal virtual {
        require(_guard != address(0), "Guard cannot be zero address");
        address oldGuard = address(guard);
        guard = PauserGuard(_guard);
        emit PauserGuardUpdated(oldGuard, _guard);
    }
}
