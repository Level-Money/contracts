// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Auth, Authority} from "@solmate/src/auth/Auth.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";

interface IRewardsManagerErrors {
    error InvalidStrategy();
    error InvalidRewardAmount();
    error NotEnoughYield();
}

interface IRewardsManagerEvents {
    event Rewarded(address asset, address to, uint256 amount);
    event StrategiesUpdated(address asset, StrategyConfig[] strategies);
    event TreasuryUpdated(address from, address to);
    event VaultUpdated(address from, address to);

    event WithdrawDefaultSucceeded(address asset, uint256 collateralAmount);
    event WithdrawDefaultFailed(address asset, uint256 collateralAmount);
}

interface IRewardsManager is IRewardsManagerErrors, IRewardsManagerEvents {
    function initialize(address admin_, address vault_) external;

    /// Only callable by admin timelock
    function setVault(address vault_) external;

    /// Only callable by admin timelock
    function setTreasury(address treasury_) external;

    /// Only callable by admin timelock
    function setAllStrategies(address asset, StrategyConfig[] memory strategies) external;

    // Fetches the accrued yield across all assets and sends it to the rewarder contract
    // Caller must ensure that vault has enough of the first asset in the list to reward
    // Callable by HARVESTER_ROLE. LevelMinting should have this role
    function reward(address[] calldata assets) external;

    // Gets the amount of excess yield accrued to this contract, in the vault share's decimals
    function getAccruedYield(address[] calldata assets) external view returns (uint256);
}
