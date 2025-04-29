// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";

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
 * @title ERC4626DelayedOracle
 * @author Level (https://level.money)
 * @notice Oracle contract for ERC4626 vaults. Records the price of ERC4626 vault and returns the cached price
 * @dev Adapted from https://github.com/Steakhouse-Financial/delayed-oracle/blob/main/src/DelayedERC4626Oracle.sol
 */
contract ERC4626DelayedOracle is IERC4626Oracle {
    event Update(uint256 updatedAt, uint256 prevPrice, uint256 currPrice, uint256 nextPrice);

    IERC4626 public immutable vault;
    uint256 public immutable delay;

    uint8 public immutable decimals_;
    uint256 public immutable oneShare;

    uint256 public price;
    uint256 public nextPrice;
    uint256 public updatedAt;

    constructor(IERC4626 _vault, uint256 _delay) {
        vault = _vault;
        delay = _delay;

        IERC20Metadata asset = IERC20Metadata(vault.asset());
        decimals_ = asset.decimals();

        oneShare = 10 ** vault.decimals();

        price = vault.convertToAssets(oneShare);
        nextPrice = vault.convertToAssets(oneShare);
        updatedAt = block.timestamp;
    }

    /// @notice Update the next price of the underlying ERC4626
    /// @dev You can't call this function until the previous delay is exhausted
    function update() public {
        if (block.timestamp < updatedAt + delay) {
            revert("Can only update after the delay is passed");
        }
        uint256 prevPrice = price;

        price = nextPrice;
        nextPrice = vault.convertToAssets(oneShare);
        updatedAt = block.timestamp;

        emit Update(updatedAt, prevPrice, price, nextPrice);
    }

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
        if (block.timestamp >= updatedAt + delay) {
            return (0, int256(nextPrice), updatedAt, updatedAt, 0);
        }

        return (0, int256(price), updatedAt, updatedAt, 0);
    }
}
