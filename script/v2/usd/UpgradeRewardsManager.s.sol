// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";

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

        console2.log("Deploying RewardsManager from address %s", deployerWallet.addr);

        RewardsManager proxy = RewardsManager(config.levelContracts.rewardsManager);

        if (address(proxy) == address(0)) {
            revert InvalidProxyAddress();
        }

        RewardsManager impl = new RewardsManager();

        vm.stopBroadcast();

        // Logs
        console2.log("=====> RewardsManager deployed ....");
        console2.log("RewardsManager Implementation                   : https://etherscan.io/address/%s", address(impl));

        // Since RewardsManager is owned by timelock, we cannot directly upgrade the proxy
        // For a real deployment, use the above implementation address to externally schedule a proxy upgrade
        // through the timelock.
    }

    function verify(RewardsManager manager) public view {
        // TODO: Add verification logic here
    }
}
