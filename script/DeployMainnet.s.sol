// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./DeploymentUtils.s.sol";
import "forge-std/Script.sol";
import {lvlUSD} from "../src/lvlUSD.sol";
import {IlvlUSD} from "../src/interfaces/IlvlUSD.sol";
import "../src/interfaces/ILevelMinting.sol";
import {LevelMinting} from "../src/LevelMinting.sol";

contract DeployMainnet is Script, DeploymentUtils {
    struct Contracts {
        // E-tokens
        lvlUSD levelUSDToken;
        // E-contracts
        LevelMinting levelMintingContract;
    }

    struct Configuration {
        // Roles
        bytes32 LevelMinterRole;
    }

    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant MAX_LVLUSD_MINT_PER_BLOCK = 100_000e18;
    uint256 public constant MAX_LVLUSD_REDEEM_PER_BLOCK = 100_000e18;

    address public constant SEPOLIA_USDC =
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant MAINNET_USDT =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant SEPOLIA_CUSTODIAN =
        0xe9AF0428143E4509df4379Bd10C4850b223F2EcB;

    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployment(deployerPrivateKey);
    }

    function deployment(
        uint256 deployerPrivateKey
    ) public returns (Contracts memory) {
        address deployerAddress = vm.addr(deployerPrivateKey);
        Contracts memory contracts;

        vm.startBroadcast(deployerPrivateKey);

        contracts.levelUSDToken = new lvlUSD(deployerAddress);
        IlvlUSD ilvlUSD = IlvlUSD(address(contracts.levelUSDToken));

        // Level Minting
        address[] memory assets = new address[](1);
        // assets[0] = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        // assets[1] = address(0xae78736Cd615f374D3085123A210448E74Fc6393);
        assets[0] = address(MAINNET_USDT);
        // assets[3] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // assets[4] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        // assets[5] = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

        address[] memory oracles = new address[](1);
        oracles[0] = address(0);

        address[] memory reserves = new address[](1);
        // reserve address
        reserves[0] = address(deployerAddress);

        uint256[] memory _ratios = new uint256[](1);
        _ratios[0] = uint256(10000);

        contracts.levelMintingContract = new LevelMinting(
            ilvlUSD,
            assets,
            oracles,
            reserves,
            _ratios,
            deployerAddress,
            MAX_LVLUSD_MINT_PER_BLOCK,
            MAX_LVLUSD_REDEEM_PER_BLOCK
        );

        // Set minter role
        contracts.levelUSDToken.setMinter(
            address(contracts.levelMintingContract)
        );

        console.log("Level Deployed");
        vm.stopBroadcast();

        // Logs
        console.log("=====> Minting Level contracts deployed ....");
        console.log(
            "levelUSD                          : https://etherscan.io/address/%s",
            address(contracts.levelUSDToken)
        );
        console.log(
            "Level Minting                  : https://etherscan.io/address/%s",
            address(contracts.levelMintingContract)
        );
        return contracts;
    }
}
