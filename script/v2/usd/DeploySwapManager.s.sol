// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {SwapManager} from "@level/src/v2/usd/SwapManager.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {SwapConfig} from "@level/src/v2/usd/SwapManager.sol";

import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {BaseConfig} from "@level/config/deploy/BaseConfig.sol";

import {console2} from "forge-std/console2.sol";

/// @title DeploySwapManager
/// @notice Deploys and sets up the SwapManager contract
/// @dev As of May 28, 2025, the SwapManager has not been deployed before. Hence it's not owned by the admin timelock.
/// @dev This script can be used directly to deploy the SwapManager, set it up and transfer ownership to the admin timelock.
contract DeploySwapManager is Configurable, DeploymentUtils, Script {
    uint256 public chainId;

    Vm.Wallet public deployerWallet;

    error InvalidProxyAddress();
    error UpgradeFailed();

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
        return deploy();
    }

    function deploy() public returns (BaseConfig.Config memory) {
        vm.startBroadcast(deployerWallet.privateKey);

        console2.log("Deploying SwapManager from address %s", deployerWallet.addr);

        if (address(config.levelContracts.pauserGuard) == address(0)) {
            revert("PauserGuard must be deployed first");
        }

        if (address(config.levelContracts.rolesAuthority) == address(0)) {
            revert("RolesAuthority must be deployed first");
        }

        bytes memory constructorArgs = abi.encodeWithSignature(
            "initialize(address,address,address)",
            deployerWallet.addr,
            address(config.periphery.uniswapV3Router),
            address(config.levelContracts.pauserGuard)
        );

        SwapManager _swapManager = new SwapManager{salt: convertNameToBytes32(LevelUsdSwapManagerName)}();
        ERC1967Proxy _swapManagerProxy = new ERC1967Proxy{salt: convertNameToBytes32(LevelUsdSwapManagerName)}(
            address(_swapManager), constructorArgs
        );

        config.levelContracts.swapManager = SwapManager(address(_swapManagerProxy));

        config.levelContracts.swapManager.setAuthority(config.levelContracts.rolesAuthority);

        // Logs
        console2.log("=====> SwapManager deployed ....");
        console2.log(
            "SwapManager proxy address                  : https://etherscan.io/address/%s", address(_swapManagerProxy)
        );
        console2.log("SwapManager implementation address      : https://etherscan.io/address/%s", address(_swapManager));

        // A tick range of [-10, 10] means price must stay between $0.999 and $1.001
        // Allows only a ±0.1% movement from the $1 peg
        // This is a conservative range that allows for some flexibility while maintaining stability

        config.levelContracts.swapManager.setSwapConfig(
            address(config.tokens.usdc),
            address(config.tokens.wrappedM),
            SwapConfig({
                pool: 0x970A7749EcAA4394C8B2Bf5F2471F41FD6b79288, // wM/USDC pool
                fee: 100, //0.01%
                tickLower: -10,
                tickUpper: 10,
                slippageBps: 5, //0.05%
                active: true
            })
        );

        config.levelContracts.swapManager.setSwapConfig(
            address(config.tokens.wrappedM),
            address(config.tokens.usdc),
            SwapConfig({
                pool: 0x970A7749EcAA4394C8B2Bf5F2471F41FD6b79288, // wM/USDC pool
                fee: 100, //0.01%
                tickLower: -10,
                tickUpper: 10,
                slippageBps: 5, //0.05%
                active: true
            })
        );

        config.levelContracts.swapManager.addOracle(address(config.tokens.usdc), address(config.oracles.usdc));
        config.levelContracts.swapManager.addOracle(address(config.tokens.wrappedM), address(config.oracles.cappedMNav));
        config.levelContracts.swapManager.setHeartBeat(address(config.tokens.usdc), 1 days);
        config.levelContracts.swapManager.setHeartBeat(address(config.tokens.wrappedM), 26 hours);

        // Transfer ownership to admin timelock
        config.levelContracts.swapManager.transferOwnership(address(config.levelContracts.adminTimelock));

        vm.stopBroadcast();

        return config;
    }

    function verify(SwapManager manager) public view {
        // TODO: Add verification logic here
    }
}
