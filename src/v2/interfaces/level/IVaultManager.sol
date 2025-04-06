// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";

interface IVaultManagerEvents {
    event VaultAddressChanged();
    event LevelMintingAddresschanged();
    event RewardsExecuted();
}

interface IVaultManager is IVaultManagerEvents {
    function initialize(address admin_) external;
    function setVault(address vault_) external;
    function setMinting(address minting_) external;
    function addBaseCollateral(address asset) external;
    function removeBaseCollateral(address asset) external;
    function addAssetStrategy(address asset, address strategy, StrategyConfig calldata config) external;
    function removeAssetStrategy(address asset, address strategy) external;
    function getAssetFor(address receiptTokenOrAsset) external view returns (address);

    function isBaseCollateral(address asset) external view returns (bool);
    function getDefaultStrategies(address asset) external view returns (address[] memory);
    function setDefaultStrategies(address asset, address[] calldata strategies) external;

    function deposit(address asset, address strategy, uint256 amount) external returns (uint256 deposited);
    function withdraw(address asset, address strategy, uint256 amount) external returns (uint256 withdrawn);
    function depositDefault(address asset, uint256 amount) external returns (uint256 deposited);
    function withdrawDefault(address asset, uint256 amount) external returns (uint256 withdrawn);
}
