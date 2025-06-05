// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {RewardsDistributor} from "@level/src/v2/periphery/RewardsDistributor.sol";

import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";

import {Upgrades} from "@openzeppelin-upgrades/src/Upgrades.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {console2} from "forge-std/console2.sol";

contract DeployRewardsDistributor is Configurable, DeploymentUtils, Script {
    uint256 public chainId;

    Vm.Wallet public deployerWallet;

    function setUp() external {
        uint256 _chainId = vm.envUint("CHAIN_ID");

        setUp_(_chainId);
    }

    function setUp_(uint256 _chainId) public {
        chainId = _chainId;
        initConfig(_chainId);

        deployerWallet.addr = msg.sender;

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
        return deploy();
    }

    function deploy() public {
        if (deployerWallet.privateKey == 0) {
            vm.startBroadcast();
        } else {
            vm.startBroadcast(deployerWallet.privateKey);
        }

        console2.log("Deploying RewardsDistributor from address %s", deployerWallet.addr);

        RewardsDistributor distributor = new RewardsDistributor(
            address(config.levelContracts.levelMintingV2), address(config.levelContracts.rewardsManager)
        );

        vm.stopBroadcast();

        // Logs
        console2.log("=====> RewardsDistributor contracts deployed ....");
        console2.log(
            "RewardsDistributor Implementation                   : https://etherscan.io/address/%s",
            address(distributor)
        );
    }
}
