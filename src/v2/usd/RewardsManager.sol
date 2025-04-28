// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {RewardsManagerStorage} from "@level/src/v2/usd/RewardsManagerStorage.sol";
import {IRewardsManager} from "@level/src/v2/interfaces/level/IRewardsManager.sol";
import {PauserGuardedUpgradable} from "@level/src/v2/common/guard/PauserGuardedUpgradable.sol";
import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";

/// @title RewardsManager
/// @notice Contract for managing rewards distribution across strategies
/// @dev Inherits error and event interfaces from IRewardsManagerErrors and IRewardsManagerEvents
/// @dev Inherits interface from IRewardsManager
contract RewardsManager is
    RewardsManagerStorage,
    Initializable,
    UUPSUpgradeable,
    AuthUpgradeable,
    PauserGuardedUpgradable
{
    using VaultLib for BoringVault;
    using MathLib for uint256;

    uint256 public constant HEARTBEAT = 1 days;

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
    /// @dev The yieldAmount is the amount of yield to distribute. Should be in the redemption asset's precision.
    function reward(address[] calldata assets, uint256 yieldAmount) external notPaused requiresAuth {
        uint256 accrued = getAccruedYield(assets);
        address redemptionAsset = assets[0];

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
        for (uint256 i = 0; i < strategies.length; i++) {
            if (address(strategies[i].baseCollateral) != asset) {
                revert InvalidStrategy();
            }
        }
        allStrategies[asset] = strategies;

        emit StrategiesUpdated(asset, strategies);
    }

    //------- View functions ---------

    /// @inheritdoc IRewardsManager
    /// @dev the assets array should always be base tokens (USDC, USDT, etc.)
    function getAccruedYield(address[] calldata assets) public returns (uint256 accrued) {
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

    /// Returns the total assets in the vault for a given asset, to the asset's precision
    function getTotalAssets(address asset) external view returns (uint256 assets) {
        StrategyConfig[] memory strategies = allStrategies[asset];

        assets = vault._getTotalAssets(strategies, asset);

        return assets;
    }

    // -------- SETTERS --------

    function updateOracle(address collateral, address oracle) public requiresAuth {
        if (collateral == address(0) || oracle == address(0)) revert InvalidAddress();
        oracles[collateral] = oracle;
    }

    // -------- Upgradeable --------
    function _authorizeUpgrade(address newImplementation) internal override requiresAuth {}

    function setGuard(address guard_) external requiresAuth {
        _setGuard(guard_);
    }
}
