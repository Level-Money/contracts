// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";

import {Authority} from "@solmate/src/auth/Auth.sol";
import {IPool} from "@level/src/v2/interfaces/aave/IPool.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {console2} from "forge-std/console2.sol";
import {StrategyLib, StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {VaultManagerStorage} from "@level/src/v2/usd/VaultManagerStorage.sol";

contract VaultManager is VaultManagerStorage, Initializable, UUPSUpgradeable, AuthUpgradeable {
    using VaultLib for BoringVault;

    constructor(address vault_) VaultManagerStorage(vault_) {
        _disableInitializers();
    }

    function initialize(address admin_) external initializer {
        __UUPSUpgradeable_init();
        __Auth_init(admin_, address(0));
    }

    // Only callable by the owner (admin timelock)
    function setVault(address _vault) external requiresAuth {
        vault = BoringVault(payable(_vault));
        emit VaultAddressChanged();
    }

    // Only callable by the owner (admin timelock)
    function setMinting(address _levelMinting) external requiresAuth {
        levelMinting = LevelMintingV2(_levelMinting);
        emit LevelMintingAddresschanged();
    }

    /// @notice Only callable by the owner (admin timelock)
    function addBaseCollateral(address _asset) external requiresAuth {
        if (_asset == address(0)) {
            revert("VaultManager: invalid asset");
        }
        isBaseCollateral[_asset] = true;
    }

    /// @notice Only callable by the owner (admin timelock)
    function removeBaseCollateral(address _asset) external requiresAuth {
        if (_asset == address(0)) {
            revert("VaultManager: invalid asset");
        }
        isBaseCollateral[_asset] = false;
    }

    // Only callable by the owner (admin timelock)
    // TODO: check for correctness
    function addAssetStrategy(address _asset, address _strategy, StrategyConfig calldata _config)
        external
        requiresAuth
    {
        if (_asset == address(0) || _strategy == address(0)) {
            revert("VaultManager: invalid asset or strategy");
        }

        if (assetToStrategy[_asset][_strategy].category != StrategyCategory.UNDEFINED) {
            revert("VaultManager: strategy already exists");
        }

        assetToStrategy[_asset][_strategy] = _config;
        receiptTokenToAsset[address(_config.receiptToken)] = _asset;
    }

    // TODO: check for correctness
    function removeAssetStrategy(address _asset, address _strategy) external requiresAuth {
        if (assetToStrategy[_asset][_strategy].category == StrategyCategory.UNDEFINED) {
            revert("VaultManager: strategy does not exist");
        }

        StrategyConfig memory _config = assetToStrategy[_asset][_strategy];

        delete assetToStrategy[_asset][_strategy];
        delete receiptTokenToAsset[address(_config.receiptToken)];
    }

    function getAssetFor(address _receiptTokenOrAsset) external view returns (address) {
        if (isBaseCollateral[_receiptTokenOrAsset]) {
            return _receiptTokenOrAsset;
        }
        return receiptTokenToAsset[_receiptTokenOrAsset];
    }

    function setDefaultStrategies(address _asset, address[] calldata strategies) external requiresAuth {
        if (strategies.length == 0) {
            revert("VaultManager: no strategies provided");
        }

        // Validate strategy already in assetToStrategy
        for (uint256 i = 0; i < strategies.length; i++) {
            if (assetToStrategy[_asset][strategies[i]].category == StrategyCategory.UNDEFINED) {
                revert("VaultManager: invalid strategy");
            }
        }

        defaultStrategies[_asset] = strategies;
    }

    function getDefaultStrategies(address _asset) external view returns (address[] memory strategies) {
        return defaultStrategies[_asset];
    }

    // Deposit asset into the vault. Shares should be minted 1:1 with the underlying, and shares should be stored in the vault.
    // Only callable by DEPOSIT_ROLE. LevelMinting should have this role
    function _deposit(address asset, address strategy, uint256 amount) internal returns (uint256 deposited) {
        if (strategy == address(0)) {
            return 0;
        }

        StrategyConfig memory config = assetToStrategy[asset][strategy];

        return vault._deposit(config, amount);
    }

    // Withdraw asset from the vault. Shares should be burned 1:1 with the underlying, and shares should be taken from the vault.
    // Only callable by WITHDRAW_ROLE. LevelMinting should have this role
    function _withdraw(address asset, address strategy, uint256 amount) internal returns (uint256 withdrawn) {
        if (strategy == address(0)) {
            return 0;
        }
        StrategyConfig memory config = assetToStrategy[asset][strategy];

        return vault._withdraw(config, amount);
    }

    function deposit(address asset, address strategy, uint256 amount)
        external
        requiresAuth
        returns (uint256 deposited)
    {
        return _deposit(asset, strategy, amount);
    }

    function withdraw(address asset, address strategy, uint256 amount)
        external
        requiresAuth
        returns (uint256 withdrawn)
    {
        return _withdraw(asset, strategy, amount);
    }

    function depositDefault(address asset, uint256 amount) external requiresAuth returns (uint256 deposited) {
        return _deposit(asset, defaultStrategies[asset][0], amount);
    }

    function withdrawDefault(address asset, uint256 amount) external requiresAuth returns (uint256 withdrawn) {
        StrategyConfig[] memory strategies = new StrategyConfig[](defaultStrategies[asset].length);
        for (uint256 i; i < defaultStrategies[asset].length; i++) {
            address strategy = defaultStrategies[asset][i];
            strategies[i] = assetToStrategy[asset][strategy];
        }

        return vault._withdrawBatch(strategies, asset, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override requiresAuth {}
}
