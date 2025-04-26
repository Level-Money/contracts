// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {IVaultManager} from "@level/src/v2/interfaces/level/IVaultManager.sol";

abstract contract VaultManagerStorage is IVaultManager {
    BoringVault public vault;

    // asset => strategy addresses
    mapping(address => address[]) public defaultStrategies;

    // asset => strategy => StrategyType
    mapping(address => mapping(address => StrategyConfig)) public assetToStrategy;
    // strategy => asset
    mapping(address => address) public receiptTokenToAsset;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
