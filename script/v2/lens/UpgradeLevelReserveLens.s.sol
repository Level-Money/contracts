// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {LevelReserveLens} from "@level/src/v2/lens/LevelReserveLens.sol";

import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";

import {Upgrades} from "@openzeppelin-upgrades/src/Upgrades.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {console2} from "forge-std/console2.sol";

contract UpgradeLevelReserveLens is Configurable, DeploymentUtils, Script {
    uint256 public chainId;

    Vm.Wallet public deployerWallet;

    IERC20Metadata usdc = IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20Metadata usdt = IERC20Metadata(0xdAC17F958D2ee523a2206206994597C13D831ec7);

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

        console2.log("Deploying LevelReserveLens from address %s", deployerWallet.addr);

        LevelReserveLens proxy = LevelReserveLens(config.levelContracts.levelReserveLens);

        LevelReserveLens impl = new LevelReserveLens();

        if (impl.rewardsManager() == address(0)) {
            revert("Rewards manager not set");
        }

        vm.stopBroadcast();

        // Logs
        console2.log("=====> Level lens contracts deployed ....");
        console2.log(
            "LevelReserveLens Implementation                   : https://etherscan.io/address/%s", address(impl)
        );

        vm.startBroadcast(config.users.admin);

        console2.log("Upgrading LevelReserveLens from proxy %s", address(proxy));
        // console2.log("Old implementation: %s", address(proxy.implementation()));
        console2.log("New implementation: %s", address(impl));

        proxy.upgradeToAndCall(address(impl), "");

        vm.stopBroadcast();

        // verify(impl);
    }

    function verify(LevelReserveLens lens) public view {
        console2.log("Owner", lens.owner());
        console2.log("USDC Reserves", lens.getReserves(address(config.tokens.usdc)));
        console2.log("USDT Reserves", lens.getReserves(address(config.tokens.usdt)));
        console2.log("USDC Mint Price", lens.getMintPrice(IERC20Metadata(address(config.tokens.usdc))));
        console2.log("USDT Mint Price", lens.getMintPrice(IERC20Metadata(address(config.tokens.usdt))));
        console2.log("USDC Redeem Price", lens.getRedeemPrice(IERC20Metadata(address(config.tokens.usdc))));
        console2.log("USDT Redeem Price", lens.getRedeemPrice(IERC20Metadata(address(config.tokens.usdt))));
    }
}
