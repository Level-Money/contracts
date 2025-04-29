// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {StrategyLib, StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {RewardsManagerStorage} from "@level/src/v2/usd/RewardsManagerStorage.sol";
import {IRewardsManager} from "@level/src/v2/interfaces/level/IRewardsManager.sol";
import {PauserGuardedUpgradable} from "@level/src/v2/common/guard/PauserGuardedUpgradable.sol";
import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";

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
 * @title RewardsManager
 * @author Level (https://level.money)
 * @notice Contract for managing rewards distribution across strategies
 * @dev Inherits error and event interfaces from IRewardsManagerErrors and IRewardsManagerEvents
 * @dev Inherits interface from IRewardsManager
 */
contract RewardsManager is
    RewardsManagerStorage,
    Initializable,
    UUPSUpgradeable,
    AuthUpgradeable,
    PauserGuardedUpgradable
{
    using VaultLib for BoringVault;
    using MathLib for uint256;
    using StrategyLib for StrategyConfig;

    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_, address vault_, address guard_) external initializer {
        vault = BoringVault(payable(vault_));
        __UUPSUpgradeable_init();
        __Auth_init(admin_, address(0));
        __PauserGuarded_init(guard_);
    }

    // ----- External --------
    /// @inheritdoc IRewardsManager
    function reward(address redemptionAsset, uint256 yieldAmount) external notPaused requiresAuth {
        if (!_inAllBaseCollateral(redemptionAsset)) {
            revert InvalidBaseCollateral();
        }

        uint256 accrued = getAccruedYield(allBaseCollateral);

        if (accrued == 0) {
            revert NotEnoughYield();
        }

        uint256 accruedAssets = accrued.convertDecimalsDown(vault.decimals(), ERC20(redemptionAsset).decimals());

        if (yieldAmount > accruedAssets) {
            revert NotEnoughYield();
        }

        uint256 availableCollateral = ERC20(redemptionAsset).balanceOf(address(vault));

        if (availableCollateral < yieldAmount) {
            uint256 toWithdraw = yieldAmount - availableCollateral;
            vault._withdrawBatch(allStrategies[redemptionAsset], toWithdraw);
        }

        vault.exit(treasury, ERC20(redemptionAsset), yieldAmount, address(vault), 0);

        emit Rewarded(redemptionAsset, treasury, yieldAmount);
    }

    //------- Setters ---------

    /// @inheritdoc IRewardsManager
    function setVault(address vault_) external notPaused requiresAuth {
        address from = address(vault);
        vault = BoringVault(payable(vault_));
        emit VaultUpdated(from, vault_);
    }

    /// @inheritdoc IRewardsManager
    function setTreasury(address treasury_) external notPaused requiresAuth {
        address from = address(treasury);
        treasury = treasury_;
        emit TreasuryUpdated(from, treasury_);
    }

    /// @inheritdoc IRewardsManager
    function setAllStrategies(address asset, StrategyConfig[] memory strategies) external notPaused requiresAuth {
        if (!_inAllBaseCollateral(asset)) {
            revert InvalidBaseCollateral();
        }

        for (uint256 i = 0; i < strategies.length; i++) {
            StrategyConfig memory config = strategies[i];

            config.validateStrategy(asset);
        }

        allStrategies[asset] = strategies;

        emit StrategiesUpdated(asset, strategies);
    }

    /// @inheritdoc IRewardsManager
    function setAllBaseCollateral(address[] calldata _allBaseCollateral) external notPaused requiresAuth {
        if (_allBaseCollateral.length == 0) {
            revert InvalidBaseCollateralArray();
        }
        emit AllBaseCollateralUpdated(allBaseCollateral, _allBaseCollateral);
        allBaseCollateral = _allBaseCollateral;
    }

    function setGuard(address guard_) external requiresAuth {
        _setGuard(guard_);
    }

    /// @inheritdoc IRewardsManager
    function updateOracle(address collateral, address oracle) external notPaused requiresAuth {
        if (collateral == address(0) || oracle == address(0)) revert InvalidAddress();
        oracles[collateral] = oracle;
    }

    //------- View functions ---------

    /// @inheritdoc IRewardsManager
    /// @dev the assets array should always be base tokens (USDC, USDT, etc.)
    function getAccruedYield(address[] memory assets) public returns (uint256 accrued) {
        uint256 total;

        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];

            StrategyConfig[] memory strategies = allStrategies[asset];

            // Update oracles for strategies
            for (uint256 j = 0; j < strategies.length; j++) {
                if (address(strategies[j].oracle) != address(0)) {
                    OracleLib._tryUpdateOracle(address(strategies[j].oracle));
                }
            }

            uint256 totalForAsset = vault._getTotalAssets(strategies, asset);

            OracleLib._tryUpdateOracle(oracles[asset]);
            (int256 price, uint256 decimals) = OracleLib.getPriceAndDecimals(oracles[asset], HEARTBEAT);
            uint256 adjustedAmount;

            // Check if price is under peg
            if (uint256(price) < 10 ** decimals) {
                adjustedAmount = totalForAsset.mulDivDown(uint256(price), 10 ** decimals);
                total += adjustedAmount.convertDecimalsDown(ERC20(asset).decimals(), vault.decimals());
            } else {
                total += totalForAsset.convertDecimalsDown(ERC20(asset).decimals(), vault.decimals());
            }
        }

        uint256 vaultShares = vault.balanceOf(address(vault));

        if (total <= vaultShares) {
            // If the total is less than the vault shares, return 0
            // This can happen if the price is under peg
            return 0;
        }

        accrued = total - vaultShares;

        return accrued;
    }

    /// @inheritdoc IRewardsManager
    function getAllStrategies(address asset) external view returns (StrategyConfig[] memory) {
        return allStrategies[asset];
    }

    /// @inheritdoc IRewardsManager
    function getTotalAssets(address asset) external view returns (uint256 assets) {
        StrategyConfig[] memory strategies = allStrategies[asset];

        assets = vault._getTotalAssets(strategies, asset);

        return assets;
    }

    // ------- Internal -------------
    /// @notice Checks if an asset is in the allBaseCollateral array
    /// @param asset The asset to check
    /// @return bool True if the asset is in the allBaseCollateral array, false otherwise
    function _inAllBaseCollateral(address asset) internal view returns (bool) {
        for (uint256 i = 0; i < allBaseCollateral.length; i++) {
            if (allBaseCollateral[i] == asset) {
                return true;
            }
        }
        return false;
    }

    // -------- Upgradeable --------
    function _authorizeUpgrade(address newImplementation) internal override requiresAuth {}
}
