// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Auth, Authority} from "@solmate/src/auth/Auth.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";

/// @title IRewardsManagerErrors
/// @notice Interface for error definitions
interface IRewardsManagerErrors {
    error InvalidStrategy();
    error InvalidRewardAmount();
    error NotEnoughYield();
    error NoStrategiesProvided();
}

/// @title IRewardsManagerEvents
/// @notice Interface for event definitions
interface IRewardsManagerEvents {
    /// @notice Emitted when a reward is distributed
    /// @param asset The asset that was rewarded
    /// @param to The recipient of the reward
    /// @param amount The amount of the reward
    event Rewarded(address asset, address to, uint256 amount);

    /// @notice Emitted when strategies are updated
    /// @param asset The asset for which strategies were updated
    /// @param strategies Array of strategy configurations
    event StrategiesUpdated(address asset, StrategyConfig[] strategies);

    /// @notice Emitted when treasury is updated
    /// @param from The previous treasury address
    /// @param to The new treasury address
    event TreasuryUpdated(address from, address to);

    /// @notice Emitted when vault is updated
    /// @param from The previous vault address
    /// @param to The new vault address
    event VaultUpdated(address from, address to);

    /// @notice Emitted when withdrawal is successful
    /// @param asset The asset that was withdrawn
    /// @param collateralAmount The amount of collateral withdrawn
    event WithdrawDefaultSucceeded(address asset, uint256 collateralAmount);

    /// @notice Emitted when withdrawal fails
    /// @param asset The asset that was attempted to be withdrawn
    /// @param collateralAmount The amount of collateral that was attempted to be withdrawn
    event WithdrawDefaultFailed(address asset, uint256 collateralAmount);
}

/// @title IRewardsManager
/// @notice Interface for managing rewards distribution across strategies
/// @dev Inherits error and event interfaces from IRewardsManagerErrors and IRewardsManagerEvents
interface IRewardsManager is IRewardsManagerErrors, IRewardsManagerEvents {
    error InvalidAddress();
    error InvalidHeartbeat();

    /// @notice Initializes the contract with admin and vault addresses
    /// @param admin_ Address of the admin who will have administrative privileges
    /// @param vault_ Address of the vault contract that holds the assets
    /// @param guard_ Address of the guard contract
    function initialize(address admin_, address vault_, address guard_) external;

    /// @notice Sets a new vault address
    /// @dev Only callable by admin timelock
    /// @param vault_ The new vault address
    function setVault(address vault_) external;

    /// @notice Sets a new treasury address
    /// @dev Only callable by admin timelock
    /// @param treasury_ The new treasury address
    function setTreasury(address treasury_) external;

    /// @notice Updates all strategies for a specific asset
    /// @dev Only callable by admin timelock
    /// @param asset The address of the asset for which to set strategies
    /// @param strategies Array of strategy configurations to be set
    function setAllStrategies(address asset, StrategyConfig[] memory strategies) external;

    /// @notice Harvests yield from specified assets and distributes rewards
    /// @dev Callable by HARVESTER_ROLE
    /// @dev Caller must ensure that vault has enough of the first asset in the list to reward
    /// @param assets Array of asset addresses to harvest rewards from
    /// @param yieldAmount The amount of yield to distribute
    function reward(address[] calldata assets, uint256 yieldAmount) external;

    /// @notice Calculates the total accrued yield for specified assets
    /// @dev Returns the yield amount in the vault share's decimals
    /// @param assets Array of asset addresses to calculate yield for
    /// @return Amount of excess yield accrued to this contract
    function getAccruedYield(address[] calldata assets) external returns (uint256);

    /// @notice Retrieves all strategies for a specific asset
    /// @param asset The address of the asset
    /// @return Array of strategy configurations
    function getAllStrategies(address asset) external view returns (StrategyConfig[] memory);
}
