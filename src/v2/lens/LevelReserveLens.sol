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
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";
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
    // Immutable values are incompatible with upgradeable contracts (see https://forum.openzeppelin.com/t/upgradable-contracts-instantiating-an-immutable-value/28763/2)
    // Since this contract would be updating an existing proxy's implementation, we're choosing to set this as a constant.
    address public constant rewardsManager = 0x665DD2537426A92A3F89Da8E07f093919ecacF43;

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

        try RewardsManager(rewardsManager).getTotalAssets(address(collateral)) returns (uint256 boringVaultValue) {
            return v1Reserves + boringVaultValue;
        } catch {
            return v1Reserves;
        }
    }
}
