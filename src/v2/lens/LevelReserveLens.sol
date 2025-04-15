// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {ILevelMinting} from "@level/src/v1/interfaces/ILevelMinting.sol";
import {IVault} from "@level/src/v1/interfaces/ISymbioticVault.sol";
import {AggregatorV3Interface} from "@level/src/v1/interfaces/AggregatorV3Interface.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {LevelReserveLens as LevelReserveLensV1} from "@level/src/v1/lens/LevelReserveLens.sol";

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
 * @title LevelReserveLens v2
 * @author Level (https://level.money)
 * @notice The LevelReserveLens contract is a simple contract that allows users to query the reserves backing lvlUSD per underlying collateral token address.
 * @dev It is upgradeable so that we can add future reserve managers without affecting downstream consumers.
 * @custom:changelog Adds the balance of the BoringVault
 */
contract LevelReserveLens is Initializable, OwnableUpgradeable, UUPSUpgradeable, LevelReserveLensV1 {
    // TODO: update when rewards manager is deployed
    address public constant rewardsManager = address(0);

    /**
     * @notice Helper function to get the reserves of the given collateral token.
     * @param collateral The address of the collateral token.
     * @param waCollateralAddress The address of the wrapped Aave token for the collateral.
     * @param symbioticVault The address of the Symbiotic vault for the collateral.
     * @return reserves The lvlUSD reserves for a given collateral token, in the given token's decimals.
     */
    function _getReserves(IERC20Metadata collateral, address waCollateralAddress, address symbioticVault)
        internal
        view
        override
        returns (uint256)
    {
        uint256 v1Reserves = super._getReserves(collateral, waCollateralAddress, symbioticVault);

        // uint256 boringVaultValue = VaultManager(vaultManager).getTotalAssets(address(collateral));
        uint256 boringVaultValue = 0;

        return v1Reserves + boringVaultValue;
    }
}
