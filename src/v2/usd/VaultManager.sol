// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {AuthUpgradeable} from "@level/src/v2/auth/AuthUpgradeable.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {StrategyConfig, StrategyCategory, StrategyLib} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {VaultManagerStorage} from "@level/src/v2/usd/VaultManagerStorage.sol";
import {PauserGuardedUpgradable} from "@level/src/v2/common/guard/PauserGuardedUpgradable.sol";
import {IVaultManager} from "@level/src/v2/interfaces/level/IVaultManager.sol";
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
 * @title VaultManager
 * @author Level (https://level.money)
 * @notice Contract for depositing and withdrawing into BoringVault
 */
contract VaultManager is
    VaultManagerStorage,
    Initializable,
    UUPSUpgradeable,
    AuthUpgradeable,
    PauserGuardedUpgradable
{
    using VaultLib for BoringVault;
    using OracleLib for address;
    using StrategyLib for StrategyConfig;

    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_, address guard_, address vault_) external initializer {
        __UUPSUpgradeable_init();
        __Auth_init(admin_, address(0));
        __PauserGuarded_init(guard_);
        vault = BoringVault(payable(vault_));
    }

    // ------- External ------------
    /// @inheritdoc IVaultManager
    function deposit(address asset, address strategy, uint256 amount)
        external
        requiresAuth
        notPaused
        returns (uint256 deposited)
    {
        return _deposit(asset, strategy, amount);
    }

    /// @inheritdoc IVaultManager
    function withdraw(address asset, address strategy, uint256 amount)
        external
        requiresAuth
        notPaused
        returns (uint256 withdrawn)
    {
        return _withdraw(asset, strategy, amount);
    }

    /// @inheritdoc IVaultManager
    function depositDefault(address asset, uint256 amount)
        external
        requiresAuth
        notPaused
        returns (uint256 deposited)
    {
        return _deposit(asset, defaultStrategies[asset][0], amount);
    }

    /// @inheritdoc IVaultManager
    function withdrawDefault(address asset, uint256 amount)
        external
        requiresAuth
        notPaused
        returns (uint256 withdrawn)
    {
        StrategyConfig[] memory strategies = new StrategyConfig[](defaultStrategies[asset].length);
        for (uint256 i; i < defaultStrategies[asset].length; i++) {
            address strategy = defaultStrategies[asset][i];
            strategies[i] = assetToStrategy[asset][strategy];
        }

        return vault._withdrawBatch(strategies, amount);
    }

    function setGuard(address _guard) external requiresAuth {
        _setGuard(_guard);
    }

    // ------- Setters -------------

    /// @inheritdoc IVaultManager
    function setVault(address _vault) external requiresAuth {
        address from = address(vault);
        vault = BoringVault(payable(_vault));
        emit VaultAddressChanged(from, _vault);
    }

    /// @inheritdoc IVaultManager
    function addAssetStrategy(address _asset, address _strategy, StrategyConfig calldata _config)
        external
        requiresAuth
    {
        if (_asset == address(0) || _strategy == address(0)) {
            revert InvalidAssetOrStrategy();
        }

        if (assetToStrategy[_asset][_strategy].category != StrategyCategory.UNDEFINED) {
            revert StrategyAlreadyExists();
        }

        assetToStrategy[_asset][_strategy] = _config;
        receiptTokenToAsset[address(_config.receiptToken)] = _asset;

        emit AssetStrategyAdded(_asset, _strategy, _config);
    }

    /// @inheritdoc IVaultManager
    function removeAssetStrategy(address _asset, address _strategy) external requiresAuth {
        if (assetToStrategy[_asset][_strategy].category == StrategyCategory.UNDEFINED) {
            revert StrategyDoesNotExist();
        }

        StrategyConfig memory _config = assetToStrategy[_asset][_strategy];

        // Remove from defaultStrategies if present, preserving order
        address[] storage defaultStrats = defaultStrategies[_asset];
        uint256 strategyIndex = type(uint256).max; // value indicating not found

        // Find the index of the strategy to remove
        for (uint256 i = 0; i < defaultStrats.length; i++) {
            if (defaultStrats[i] == _strategy) {
                strategyIndex = i;
                break;
            }
        }

        // If the strategy was found in the default strategies array
        if (strategyIndex != type(uint256).max) {
            // Shift elements to the left to fill the gap
            for (uint256 i = strategyIndex; i < defaultStrats.length - 1; i++) {
                defaultStrats[i] = defaultStrats[i + 1];
            }
            // Remove the last element
            defaultStrats.pop();
        }

        delete assetToStrategy[_asset][_strategy];
        delete receiptTokenToAsset[address(_config.receiptToken)];

        emit AssetStrategyRemoved(_asset, _strategy);
    }

    /// @inheritdoc IVaultManager
    function setDefaultStrategies(address _asset, address[] calldata strategies) external requiresAuth {
        if (strategies.length == 0) {
            revert NoStrategiesProvided();
        }

        // Validate strategy already in assetToStrategy
        for (uint256 i = 0; i < strategies.length; i++) {
            StrategyConfig memory config = assetToStrategy[_asset][strategies[i]];

            config.validateStrategy(_asset);
        }

        defaultStrategies[_asset] = strategies;
        emit DefaultStrategiesSet(_asset, strategies);
    }

    // ------- Aave Umbrella ---------

    /// @notice Approve or revoke an address to be able to start the cooldown of boring vault on Umbrella
    /// @param operator The address to approve or revoke
    /// @param umbrellaVault The umbrella vault to modify the cooldown operator for
    /// @param isApproved Whether to approve or revoke the operator
    /// @dev callable only by the STRATEGIST_ROLE (e.g. operator)
    /// @dev will emit a CooldownOnBehalfChanged event from the umbrella vault
    /// @dev if an approved operator calls cooldown during an ongoing cooldown, the timer will start over
    function modifyAaveUmbrellaCooldownOperator(address operator, address umbrellaVault, bool isApproved)
        external
        requiresAuth
    {
        if (operator == address(0) || umbrellaVault == address(0)) {
            revert InvalidOperatorOrUmbrellaVault();
        }

        vault.manage(
            address(umbrellaVault),
            abi.encodeWithSignature("setCooldownOperator(address,bool)", operator, isApproved),
            0
        );
    }

    /// @notice Approve or revoke an address to be able to claim rewards from Aave Umbrella on behalf of the vault
    /// @param rewardsClaimer The address to approve or revoke
    /// @param umbrellaRewardsController The umbrella rewards controller of Aave Umbrella
    /// @param isApproved Whether to approve or revoke the rewards claimer
    /// @dev callable only by the STRATEGIST_ROLE (e.g. operator)
    /// @dev will emit a ClaimerSet event from the umbrella rewards controller
    function modifyAaveUmbrellaRewardsClaimer(
        address rewardsClaimer,
        address umbrellaRewardsController,
        bool isApproved
    ) external requiresAuth {
        if (rewardsClaimer == address(0) || umbrellaRewardsController == address(0)) {
            revert InvalidOperatorOrUmbrellaVault();
        }

        vault.manage(
            address(umbrellaRewardsController),
            abi.encodeWithSignature("setClaimer(address,bool)", rewardsClaimer, isApproved),
            0
        );
    }

    // ------- Internal ------------
    /// @notice Internal function to deposit an asset into the vault
    /// @param asset The address of the asset to deposit
    /// @param strategy The strategy configuration
    /// @param amount The amount of the asset to deposit
    /// @return deposited The actual amount deposited
    function _deposit(address asset, address strategy, uint256 amount) internal returns (uint256 deposited) {
        if (strategy == address(0)) {
            return 0;
        }

        StrategyConfig memory config = assetToStrategy[asset][strategy];

        if (config.category == StrategyCategory.UNDEFINED) {
            revert InvalidStrategy();
        }

        // Try to update oracle before deposit
        address(config.oracle)._tryUpdateOracle();

        deposited = vault._deposit(config, amount);
        emit Deposit(asset, config, deposited);
        return deposited;
    }

    /// @notice Internal function to withdraw an asset from the vault
    /// @param asset The address of the asset to withdraw
    /// @param strategy The strategy configuration
    /// @param amount The amount of the asset to withdraw
    /// @return withdrawn The actual amount withdrawn
    function _withdraw(address asset, address strategy, uint256 amount) internal returns (uint256 withdrawn) {
        if (strategy == address(0)) {
            return 0;
        }
        StrategyConfig memory config = assetToStrategy[asset][strategy];

        if (config.category == StrategyCategory.UNDEFINED) {
            revert InvalidStrategy();
        }

        // Try to update oracle before withdraw
        address(config.oracle)._tryUpdateOracle();

        withdrawn = vault._withdraw(config, amount);
        emit Withdraw(asset, config, withdrawn);
        return withdrawn;
    }

    // ------- View functions ------
    /// @inheritdoc IVaultManager
    function getUnderlyingAssetFor(address _receiptToken) external view returns (address) {
        return receiptTokenToAsset[_receiptToken];
    }

    /// @inheritdoc IVaultManager
    function getDefaultStrategies(address _asset) external view returns (address[] memory strategies) {
        return defaultStrategies[_asset];
    }

    // ------- Upgradeable ---------

    function _authorizeUpgrade(address newImplementation) internal override requiresAuth {}
}
