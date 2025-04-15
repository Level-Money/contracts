// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";

interface IVaultManagerEvents {
    event VaultAddressChanged(address indexed from, address indexed to);
    event BaseCollateralAdded(address indexed asset);
    event BaseCollateralRemoved(address indexed asset);
    event AssetStrategyAdded(address indexed asset, address indexed strategy, StrategyConfig config);
    event AssetStrategyRemoved(address indexed asset, address indexed strategy);
    event DefaultStrategiesSet(address indexed asset, address[] strategies);
    event Deposit(address indexed asset, StrategyConfig strategy, uint256 deposited);
    event Withdraw(address indexed asset, StrategyConfig strategy, uint256 withdrawn);
}

interface IVaultManagerErrors {
    error InvalidAsset();
    error InvalidStrategy();
    error InvalidAssetOrStrategy();
    error StrategyAlreadyExists();
    error StrategyDoesNotExist();
    error NoStrategiesProvided();
}

interface IVaultManager is IVaultManagerEvents, IVaultManagerErrors {
    function initialize(address admin_, address guard_) external;
    function setVault(address vault_) external;
    function addAssetStrategy(address asset, address strategy, StrategyConfig calldata config) external;
    function removeAssetStrategy(address asset, address strategy) external;
    function getUnderlyingAssetFor(address receiptToken) external view returns (address);

    function getDefaultStrategies(address asset) external view returns (address[] memory);
    function setDefaultStrategies(address asset, address[] calldata strategies) external;

    function deposit(address asset, address strategy, uint256 amount) external returns (uint256 deposited);
    function withdraw(address asset, address strategy, uint256 amount) external returns (uint256 withdrawn);
    function depositDefault(address asset, uint256 amount) external returns (uint256 deposited);
    function withdrawDefault(address asset, uint256 amount) external returns (uint256 withdrawn);
}
