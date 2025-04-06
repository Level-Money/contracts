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
import {console2} from "forge-std/console2.sol";
import {RewardsManagerStorage} from "@level/src/v2/usd/RewardsManagerStorage.sol";

contract RewardsManager is RewardsManagerStorage, Initializable, UUPSUpgradeable, AuthUpgradeable {
    using VaultLib for BoringVault;
    using MathLib for uint256;

    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_, address vault_) external initializer {
        vault = BoringVault(payable(vault_));
        __UUPSUpgradeable_init();
        __Auth_init(admin_, address(0));
    }

    /// Only callable by admin timelock
    function setVault(address vault_) external requiresAuth {
        vault = BoringVault(payable(vault_));
        // emit VaultAddressChanged();
    }

    /// Only callable by admin timelock
    function setTreasury(address treasury_) external requiresAuth {
        treasury = treasury_;
    }

    // Fetches the accrued yield across all assets and sends it to the rewarder contract
    // Callable by HARVESTER_ROLE. LevelMinting should have this role
    function reward(address[] calldata assets) external requiresAuth {
        uint256 accrued = getAccruedYield(assets);
        address redemptionAsset = assets[0];
        if (accrued > 0) {
            uint256 accruedAsset = accrued.convertDecimalsDown(vault.decimals(), ERC20(redemptionAsset).decimals());

            uint256 withdrawn = vault._withdrawBatch(allStrategies[redemptionAsset], redemptionAsset, accruedAsset);

            vault.exit(treasury, ERC20(redemptionAsset), accruedAsset, address(vault), 0);
        }
        // emit RewardsExecuted();
    }

    // Gets the amount of excess yield accrued to this contract, in the vault share's decimals
    function getAccruedYield(address[] calldata assets) public view returns (uint256 accrued) {
        uint256 total;

        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];

            StrategyConfig[] memory strategies = allStrategies[asset];

            uint256 totalForAsset = vault._getTotalAssets(strategies, asset);

            total += totalForAsset.mulDivDown(10 ** vault.decimals(), 10 ** ERC20(asset).decimals());
        }

        uint256 vaultShares = vault.balanceOf(address(vault));
        accrued = total - vaultShares;

        return accrued;
    }

    function setAllStrategies(address asset, StrategyConfig[] memory strategies) external requiresAuth {
        for (uint256 i = 0; i < strategies.length; i++) {
            if (address(strategies[i].baseCollateral) != asset) {
                revert("Strategy must match asset");
            }
        }
        allStrategies[asset] = strategies;
    }

    function getAllStrategies(address asset) external view returns (StrategyConfig[] memory) {
        return allStrategies[asset];
    }

    function _authorizeUpgrade(address newImplementation) internal override requiresAuth {}
}
