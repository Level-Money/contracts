// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {Roles} from "@level/config/Roles.sol";
import {ContractNames} from "@level/config/ContractNames.sol";

import {BaseConfig} from "@level/config/deploy/BaseConfig.sol";

import {Mainnet} from "@level/config/deploy/Mainnet.sol";
import {CommonBase} from "forge-std/Base.sol";
import {console2} from "forge-std/console2.sol";

contract Configurable is Roles, ContractNames, CommonBase {
    bool public activated;

    BaseConfig.Config public config;

    function initConfig(uint256 _chainId) public {
        if (activated) {
            return;
        }

        if (_chainId == 1) {
            activated = true;
            Mainnet mainnetConfig = new Mainnet();

            config = mainnetConfig.initialize();
        } else {
            revert("Invalid chainId");
        }

        _labelAddresses();
    }

    function _labelAddresses() internal {
        _labelAddress(address(config.levelContracts.rolesAuthority), "levelContracts.rolesAuthority");
        _labelAddress(address(config.levelContracts.levelMintingV2), "levelContracts.levelMintingV2");
        _labelAddress(address(config.levelContracts.boringVault), "levelContracts.boringVault");
        _labelAddress(address(config.levelContracts.vaultManager), "levelContracts.vaultManager");
        _labelAddress(address(config.levelContracts.adminTimelock), "levelContracts.adminTimelock");
        _labelAddress(address(config.levelContracts.pauserGuard), "levelContracts.pauserGuard");

        _labelAddress(address(config.tokens.usdc), "tokens.usdc");
        _labelAddress(address(config.tokens.usdt), "tokens.usdt");
        _labelAddress(address(config.tokens.lvlUsd), "tokens.lvlUsd");
        _labelAddress(address(config.tokens.slvlUsd), "tokens.slvlUsd");
        _labelAddress(address(config.tokens.aUsdc), "tokens.aUsdc");
        _labelAddress(address(config.tokens.aUsdt), "tokens.aUsdt");

        _labelAddress(address(config.morphoVaults.steakhouseUsdc.vault), "morphoVaults.steakhouseUsdc");
        _labelAddress(address(config.morphoVaults.steakhouseUsdt.vault), "morphoVaults.steakhouseUsdt");
        _labelAddress(address(config.morphoVaults.re7Usdc.vault), "morphoVaults.re7Usdc");
        _labelAddress(address(config.morphoVaults.steakhouseUsdtLite.vault), "morphoVaults.steakhouseUsdtLite");

        _labelAddress(address(config.users.admin), "users.admin");
        _labelAddress(address(config.users.deployer), "users.deployer");
        _labelAddress(address(config.users.operator), "users.operator");

        _labelAddress(address(config.periphery.aaveV3), "periphery.aaveV3");
    }

    function _labelAddress(address _address, string memory _name) internal {
        if (_address == address(0)) {
            return;
        }

        vm.label(_address, _name);
    }

    function _allMorphoVaultAddresses() internal view returns (address[] memory) {
        address[] memory allMorphoVaults = new address[](4);
        allMorphoVaults[0] = address(config.morphoVaults.steakhouseUsdc.vault);
        allMorphoVaults[1] = address(config.morphoVaults.re7Usdc.vault);
        allMorphoVaults[2] = address(config.morphoVaults.steakhouseUsdt.vault);
        allMorphoVaults[3] = address(config.morphoVaults.steakhouseUsdtLite.vault);
        return allMorphoVaults;
    }
}
