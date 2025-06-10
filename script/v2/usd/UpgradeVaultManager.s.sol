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

    function setUp_(uint256 _chainId, uint256 _privateKey, BaseConfig.Config memory _config) public {
        chainId = _chainId;
        config = _config;

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

        // Setup update

        CappedOneDollarOracle mNavOracle = new CappedOneDollarOracle(address(config.oracles.mNav));
        vm.label(address(mNavOracle), "CappedMNavOracle");

        StrategyConfig memory ustbConfig = StrategyConfig({
            category: StrategyCategory.SUPERSTATE,
            baseCollateral: config.tokens.usdc,
            receiptToken: config.tokens.ustb,
            oracle: config.oracles.ustb,
            depositContract: address(config.tokens.ustb),
            withdrawContract: address(config.periphery.ustbRedemptionIdle),
            heartbeat: 1 days
        });

        StrategyConfig memory mConfig = StrategyConfig({
            category: StrategyCategory.M0,
            baseCollateral: config.tokens.usdc,
            receiptToken: config.tokens.wrappedM,
            oracle: AggregatorV3Interface(address(mNavOracle)),
            depositContract: address(config.levelContracts.swapManager),
            withdrawContract: address(config.levelContracts.swapManager),
            heartbeat: 26 hours
        });

        address[] memory targets = new address[](5);
        targets[0] = address(config.levelContracts.vaultManager);
        targets[1] = address(config.levelContracts.vaultManager);
        targets[2] = address(config.levelContracts.vaultManager);
        targets[3] = address(config.levelContracts.rolesAuthority);
        targets[4] = address(config.levelContracts.rolesAuthority);

        bytes[] memory payloads = new bytes[](5);
        // Upgrade to new implementation
        payloads[0] = abi.encodeWithSelector(proxy.upgradeToAndCall.selector, address(impl), "");
        // Add ustb as a strategy
        payloads[1] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.addAssetStrategy.selector,
            address(config.tokens.usdc),
            address(config.tokens.ustb),
            ustbConfig
        );
        // Add m as a strategy
        payloads[2] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.addAssetStrategy.selector,
            address(config.tokens.usdc),
            address(config.tokens.wrappedM),
            mConfig
        );
        // Add cooldown operator capability to strategist role
        payloads[3] = abi.encodeWithSelector(
            config.levelContracts.rolesAuthority.setRoleCapability.selector,
            STRATEGIST_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("modifyAaveUmbrellaCooldownOperator(address,address,bool)")),
            true
        );
        // Add rewards claimer capability to strategist role
        payloads[4] = abi.encodeWithSelector(
            config.levelContracts.rolesAuthority.setRoleCapability.selector,
            STRATEGIST_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("modifyAaveUmbrellaRewardsClaimer(address,address,bool)")),
            true
        );

        vm.startBroadcast(config.users.admin);

        TimelockController timelock = TimelockController(payable(config.levelContracts.adminTimelock));
        timelock.scheduleBatch(targets, new uint256[](5), payloads, bytes32(0), bytes32(0), 5 days);

        vm.warp(block.timestamp + 5 days);

        timelock.executeBatch(targets, new uint256[](5), payloads, bytes32(0), bytes32(0));

        vm.stopBroadcast();

        return config;

        // verify(impl);

        /*   STEPS AFTER UPGRADE

        - Add asset strategy for sUsdc
        if (address(config.sparkVaults.sUsdc.vault) == address(0)) {
            revert("Spark USDC vaults not deployed");
        } else {
            config.levelContracts.vaultManager.addAssetStrategy(
                address(config.tokens.usdc), address(config.sparkVaults.sUsdc.vault), sUsdcConfig
            );
        }

        - Add default strategy for USDC
        address[] memory usdcDefaultStrategies = new address[](3);
        usdcDefaultStrategies[0] = address(config.periphery.aaveV3);
        usdcDefaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        usdcDefaultStrategies[2] = address(config.sparkVaults.sUsdc.vault);

        config.levelContracts.vaultManager.setDefaultStrategies(address(config.tokens.usdc), usdcDefaultStrategies);
        */
    }

    function verify(VaultManager manager) public view {
        // TODO: Add verification logic here
    }
}
