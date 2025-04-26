// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";

/// @title IVaultManagerEvents
/// @notice Event interface for the VaultManager contract
interface IVaultManagerEvents {
    /// @notice Emitted when the vault address is changed
    /// @param from The previous vault address
    /// @param to The new vault address
    event VaultAddressChanged(address indexed from, address indexed to);

    /// @notice Emitted when a new base collateral is added
    /// @param asset The address of the new base collateral
    event BaseCollateralAdded(address indexed asset);

    /// @notice Emitted when a base collateral is removed
    /// @param asset The address of the base collateral to be removed
    event BaseCollateralRemoved(address indexed asset);

    /// @notice Emitted when a new strategy is added for a specific asset
    /// @param asset The address of the asset
    /// @param strategy The address of the strategy to add
    /// @param config Configuration parameters for the strategy
    event AssetStrategyAdded(address indexed asset, address indexed strategy, StrategyConfig config);

    /// @notice Emitted when a strategy is removed for a specific asset
    /// @param asset The address of the asset
    /// @param strategy The address of the strategy to remove
    event AssetStrategyRemoved(address indexed asset, address indexed strategy);

    /// @notice Emitted when default strategies are set for a specific asset
    /// @param asset The address of the asset
    /// @param strategies Array of strategy addresses to be set as default
    event DefaultStrategiesSet(address indexed asset, address[] strategies);

    /// @notice Emitted when an asset is deposited into a strategy
    /// @param asset The address of the asset
    /// @param strategy The strategy configuration
    /// @param deposited The amount of the asset deposited
    event Deposit(address indexed asset, StrategyConfig strategy, uint256 deposited);

    /// @notice Emitted when an asset is withdrawn from a strategy
    /// @param asset The address of the asset
    /// @param strategy The strategy configuration
    /// @param withdrawn The amount of the asset withdrawn
    event Withdraw(address indexed asset, StrategyConfig strategy, uint256 withdrawn);
}

/// @title IVaultManagerErrors
/// @notice Error interface for the VaultManager contract
interface IVaultManagerErrors {
    error InvalidAsset();
    error InvalidStrategy();
    error InvalidAssetOrStrategy();
    error StrategyAlreadyExists();
    error StrategyDoesNotExist();
    error NoStrategiesProvided();
}

/// @title IVaultManager
/// @notice Interface for managing vault operations and strategies
/// @dev Inherits error and event interfaces from IVaultManagerEvents and IVaultManagerErrors

interface IVaultManager is IVaultManagerEvents, IVaultManagerErrors {
    /// @notice Initializes the contract with admin and guard addresses
    /// @param admin_ Address of the admin who will have administrative privileges
    /// @param guard_ Address of the guard that provides security controls
    /// @param vault_ Address of the vault to be set
    function initialize(address admin_, address guard_, address vault_) external;

    /// @notice Sets the vault address
    /// @dev Restricted to admin timelock
    /// @param vault_ The address of the vault to be set
    function setVault(address vault_) external;

    /// @notice Adds a new strategy for a specific asset with configuration
    /// @dev Restricted to admin timelock
    /// @param asset The address of the asset
    /// @param strategy The address of the strategy to add
    /// @param config Configuration parameters for the strategy
    function addAssetStrategy(address asset, address strategy, StrategyConfig calldata config) external;

    /// @notice Removes a strategy for a specific asset
    /// @dev Restricted to admin timelock
    /// @param asset The address of the asset
    /// @param strategy The address of the strategy to remove
    function removeAssetStrategy(address asset, address strategy) external;

    /// @notice Returns the underlying asset address for a given receipt token
    /// @param receiptToken The address of the receipt token
    /// @return The address of the underlying asset
    function getUnderlyingAssetFor(address receiptToken) external view returns (address);

    /// @notice Gets the list of default strategies for a specific asset
    /// @param asset The address of the asset
    /// @return An array of strategy addresses that are set as default for the asset
    function getDefaultStrategies(address asset) external view returns (address[] memory);

    /// @notice Sets the default strategies for a specific asset
    /// @dev Restricted to admin timelock
    /// @param asset The address of the asset
    /// @param strategies Array of strategy addresses to set as default
    function setDefaultStrategies(address asset, address[] calldata strategies) external;

    /// @notice Deposits an amount of an asset to a specific strategy
    /// @dev Callable by STRATEGIST_ROLE
    /// @param asset The address of the asset to deposit
    /// @param strategy The address of the strategy to deposit into
    /// @param amount The amount of the asset to deposit
    /// @return deposited The actual amount deposited
    function deposit(address asset, address strategy, uint256 amount) external returns (uint256 deposited);

    /// @notice Withdraws an amount of an asset from a specific strategy
    /// @dev Callable by STRATEGIST_ROLE
    /// @param asset The address of the asset to withdraw
    /// @param strategy The address of the strategy to withdraw from
    /// @param amount The amount of the asset to withdraw
    /// @return withdrawn The actual amount withdrawn
    function withdraw(address asset, address strategy, uint256 amount) external returns (uint256 withdrawn);

    /// @notice Deposits an amount of an asset to the default strategies
    /// @dev Callable by STRATEGIST_ROLE
    /// @param asset The address of the asset to deposit
    /// @param amount The amount of the asset to deposit
    /// @return deposited The actual amount deposited
    function depositDefault(address asset, uint256 amount) external returns (uint256 deposited);

    /// @notice Withdraws an amount of an asset from the default strategies
    /// @dev Callable by STRATEGIST_ROLE
    /// @param asset The address of the asset to withdraw
    /// @param amount The amount of the asset to withdraw
    /// @return withdrawn The actual amount withdrawn
    function withdrawDefault(address asset, uint256 amount) external returns (uint256 withdrawn);
}
