// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {BaseConfig} from "@level/config/deploy/BaseConfig.sol";
import {StrategyCategory, StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {CappedOneDollarOracle} from "@level/src/v2/oracles/CappedOneDollarOracle.sol";

import {console2} from "forge-std/console2.sol";

contract UpgradeVaultManager is Configurable, DeploymentUtils, Script {
    uint256 public chainId;

    Vm.Wallet public deployerWallet;

    error InvalidProxyAddress();
    error UpgradeFailed();
    error VerificationFailed();

    function setUp() external {
        uint256 _chainId = vm.envUint("CHAIN_ID");
        setUp_(_chainId);
    }

    function setUp_(uint256 _chainId) public {
        chainId = _chainId;
        initConfig(_chainId);

        vm.label(msg.sender, "Deployer EOA");
    }

    function setUp_(uint256 _chainId, uint256 _privateKey) public {
        chainId = _chainId;
        initConfig(_chainId);

        if (msg.sender != vm.addr(_privateKey)) {
            revert("Private key does not match sender");
        }

        deployerWallet.privateKey = _privateKey;
        deployerWallet.addr = vm.addr(_privateKey);

        vm.label(msg.sender, "Deployer EOA");
    }

    function run() external returns (BaseConfig.Config memory) {
        return upgrade();
    }

    function upgrade() public returns (BaseConfig.Config memory) {
        vm.startBroadcast(deployerWallet.privateKey);

        console2.log("Deploying VaultManager from address %s", deployerWallet.addr);

        VaultManager proxy = VaultManager(config.levelContracts.vaultManager);

        if (address(proxy) == address(0)) {
            revert InvalidProxyAddress();
        }

        VaultManager impl = new VaultManager();

        vm.stopBroadcast();

        // Logs
        console2.log("=====> VaultManager deployed ....");
        console2.log("VaultManager Implementation                   : https://etherscan.io/address/%s", address(impl));

        // As the deployed vaultManager is owned by timelock, we cannot directly upgrade the proxy
        // For a real deployment, use the above implementation address to externally schedule a proxy upgrade
        // through the timelock.

        return config;

        // verify(impl);
    }

    function verify(VaultManager manager) public view {
        // TODO: Add verification logic here
    }
}
