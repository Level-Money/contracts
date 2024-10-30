// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./DeploymentUtils.s.sol";
import "forge-std/Script.sol";
import {lvlUSD} from "../src/lvlUSD.sol";
import {IlvlUSD} from "../src/interfaces/IlvlUSD.sol";
import "../src/interfaces/ILevelMinting.sol";
import "../src/interfaces/IStakedlvlUSD.sol";
import "../src/interfaces/ILevelBaseReserveManager.sol";

import {LevelMinting} from "../src/LevelMinting.sol";
import {LevelBaseReserveManager} from "../src/reserve/LevelBaseReserveManager.sol";
import {EigenlayerReserveManager} from "../src/reserve/LevelEigenlayerReserveManager.sol";
import {StakedlvlUSD} from "../src/StakedlvlUSD.sol";

// deploy Eigenlayer LRM to Holesky testnet
contract DeployHolesky is Script, DeploymentUtils {
    struct Contracts {
        lvlUSD levelUSDToken;
        LevelMinting levelMinting;
        StakedlvlUSD stakedlvlUSD;
        // BaseReserveManager levelBaseReserveManager;
        EigenlayerReserveManager eigenlayerReserveManager;
    }

    struct Configuration {
        // Roles
        bytes32 LevelMinterRole;
        bytes32 LevelRedeemerRole;
    }

    address public constant HOLESKY_ADMIN =
        0x74C3dC2F48b9cc5f167B0C8AE09FbbDc6315f519;

    address public constant HOLESKY_DELEGATION_MANAGER =
        0xA44151489861Fe9e3055d95adC98FbD462B948e7;

    address public constant HOLESKY_STRATEGY_MANAGER =
        0xdfB5f6CE42aAA7830E94ECFCcAd411beF4d4D5b6;

    address public constant HOLESKY_REWARDS_COORDINATOR =
        0xAcc1fb458a1317E886dB376Fc8141540537E68fE;

    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployment(deployerPrivateKey);
    }

    function deployment(
        uint256 deployerPrivateKey
    ) public returns (Contracts memory) {
        // address deployerAddress = vm.addr(deployerPrivateKey);
        Contracts memory contracts;

        vm.startBroadcast(deployerPrivateKey);

        // eigenlayer reserve manager
        contracts.eigenlayerReserveManager = new EigenlayerReserveManager(
            IlvlUSD(address(0x123)),
            HOLESKY_DELEGATION_MANAGER,
            HOLESKY_STRATEGY_MANAGER,
            HOLESKY_REWARDS_COORDINATOR,
            IStakedlvlUSD(address(0x234)),
            HOLESKY_ADMIN,
            HOLESKY_ADMIN,
            "operator1"
        );

        // eigenlayer reserve manager

        console.log("Level Deployed");
        vm.stopBroadcast();

        // Logs
        console.log("=====> Level contracts deployed ....");
        console.log(
            "eigenlayerReserveManager                          : https://holesky.etherscan.io/address/%s",
            address(contracts.eigenlayerReserveManager)
        );
        return contracts;
    }
}
