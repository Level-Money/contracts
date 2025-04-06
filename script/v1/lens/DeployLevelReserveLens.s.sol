// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../DeploymentUtils.s.sol";
import "forge-std/Script.sol";

import {LevelReserveLens} from "@level/src/v1/lens/LevelReserveLens.sol";
import {LevelReserveLensMorphoOracle} from "@level/src/v1/lens/LevelReserveLensMorphoOracle.sol";

import {IMorphoChainlinkOracleV2Factory} from "@level/script/v1/interfaces/morpho/IMorphoChainlinkOracleV2Factory.sol";
import {IMorphoChainlinkOracleV2} from "@level/script/v1/interfaces/morpho/IMorphoChainlinkOracleV2.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AggregatorV3Interface} from "@level/src/v1/interfaces/AggregatorV3Interface.sol";

import {Upgrades} from "@openzeppelin-upgrades/src/Upgrades.sol";
import {Options} from "@openzeppelin-upgrades/src/Options.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

contract DeployLevelReserveLens is Script, DeploymentUtils {
    struct Contracts {
        LevelReserveLens lens;
        LevelReserveLensMorphoOracle oracle;
        IMorphoChainlinkOracleV2 morphoOracle;
    }

    // Mainnet admin multisig
    address public admin = 0x343ACce723339D5A417411D8Ff57fde8886E91dc;
    // Mainnet manager agent multisig
    address public pauser = 0xcEa14C3e9Afc5822d44ADe8d006fCFBAb60f7a21;

    IERC20Metadata usdc = IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20Metadata usdt = IERC20Metadata(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    Contracts contracts;

    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");

        deployment(deployerPrivateKey);
    }

    function deployment(uint256 deployerPrivateKey) public returns (Contracts memory) {
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        console.log("Deploying LevelReserveLens from address %s", deployerAddress);

        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        address proxy =
            Upgrades.deployUUPSProxy("LevelReserveLens.sol", abi.encodeCall(LevelReserveLens.initialize, (admin)), opts);

        contracts.lens = LevelReserveLens(proxy);

        contracts.oracle = new LevelReserveLensMorphoOracle(admin, pauser, address(contracts.lens));

        IMorphoChainlinkOracleV2Factory morphoOracleFactory =
            IMorphoChainlinkOracleV2Factory(0x3A7bB36Ee3f3eE32A60e9f2b33c1e5f2E83ad766);

        contracts.morphoOracle = morphoOracleFactory.createMorphoChainlinkOracleV2(
            IERC4626(address(0)),
            1,
            contracts.oracle,
            AggregatorV3Interface(address(0)),
            18,
            IERC4626(address(0)),
            1,
            AggregatorV3Interface(address(0)),
            AggregatorV3Interface(address(0)),
            6,
            ""
        );
        vm.stopBroadcast();

        console.log("LevelReserveLens Deployed");

        _verifyDeployment();

        // Logs
        console.log("=====> Level lens contracts deployed ....");
        console.log(
            "LevelReserveLens Proxy                   : https://etherscan.io/address/%s", address(contracts.lens)
        );
        console.log(
            "LevelReserveLensMorphoOracle             : https://etherscan.io/address/%s", address(contracts.oracle)
        );
        console.log(
            "MorphoChainlinkOracleV2                  : https://etherscan.io/address/%s",
            address(contracts.morphoOracle)
        );

        return contracts;
    }

    function _verifyDeployment() public view {
        console.log("\n=====> Level lens state ....");
        console.log("Owner", contracts.lens.owner());
        console.log("USDC Reserves", contracts.lens.getReserves(address(usdc)));
        console.log("USDT Reserves", contracts.lens.getReserves(address(usdt)));
        console.log("Reserve values", contracts.lens.getReserveValue());
        console.log("USDC Mint Price", contracts.lens.getMintPrice(usdc));
        console.log("USDT Mint Price", contracts.lens.getMintPrice(usdt));
        console.log("USDC Redeem Price", contracts.lens.getRedeemPrice(usdc));
        console.log("USDT Redeem Price", contracts.lens.getRedeemPrice(usdt));

        console.log("\n=====> Level lens oracle state ....");
        console.log("Owner", contracts.oracle.owner());
        console.log("Decimals", contracts.oracle.decimals());
        console.log("Description", contracts.oracle.description());
        console.log("Paused", contracts.oracle.paused());
        (, int256 answer,,,) = contracts.oracle.latestRoundData();
        console.log("Latest Round Data", answer);

        console.log("\n=====> MorphoChainlinkOracle state ....");
        console.log("Price", contracts.morphoOracle.price());
    }

    function upgrade(uint256 deployerPrivateKey) public {
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        console.log("Deploying LevelReserveLens from address %s", deployerAddress);

        LevelReserveLens impl = new LevelReserveLens();

        vm.stopBroadcast();

        // Logs
        console.log("=====> Level lens implementation deployed ....");
        console.log(
            "LevelReserveLens Implementation                   : https://etherscan.io/address/%s", address(impl)
        );

        verify(impl);
    }

    function verify(LevelReserveLens lens) public view {
        console.log("Owner", lens.owner());
        console.log("USDC Reserves", lens.getReserves(address(usdc)));
        console.log("USDT Reserves", lens.getReserves(address(usdt)));
        console.log("USDC Mint Price", lens.getMintPrice(usdc));
        console.log("USDT Mint Price", lens.getMintPrice(usdt));
        console.log("USDC Redeem Price", lens.getRedeemPrice(usdc));
        console.log("USDT Redeem Price", lens.getRedeemPrice(usdt));
    }
}
