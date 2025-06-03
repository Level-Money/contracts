// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";

import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";

import {console2} from "forge-std/console2.sol";

contract UpgradeRewardsManager is Configurable, DeploymentUtils, Script {
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

    function run() external {
        return upgrade();
    }

    function upgrade() public {
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

        vm.startBroadcast(config.users.admin);

        console2.log("Upgrading VaultManager from proxy %s", address(proxy));
        console2.log("New implementation: %s", address(impl));

        try proxy.upgradeToAndCall(address(impl), "") {
            console2.log("Upgrade successful!");
        } catch {
            revert UpgradeFailed();
        }

        vm.stopBroadcast();

        // verify(impl);

        /*   STEPS AFTER UPGRADE

        - Add asset strategy for sUSDC
        if (address(config.sparkVaults.sUSDC.vault) == address(0)) {
            revert("Spark USDC vaults not deployed");
        } else {
            config.levelContracts.vaultManager.addAssetStrategy(
                address(config.tokens.usdc), address(config.sparkVaults.sUSDC.vault), sUsdcConfig
            );
        }

        - Add default strategy for USDC
        address[] memory usdcDefaultStrategies = new address[](3);
        usdcDefaultStrategies[0] = address(config.periphery.aaveV3);
        usdcDefaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        usdcDefaultStrategies[2] = address(config.sparkVaults.sUSDC.vault);

        config.levelContracts.vaultManager.setDefaultStrategies(address(config.tokens.usdc), usdcDefaultStrategies);
        */
    }

    function verify(VaultManager manager) public view {
        // TODO: Add verification logic here
    }
}
