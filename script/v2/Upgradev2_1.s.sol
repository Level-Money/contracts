// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";

import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";

import {console2} from "forge-std/console2.sol";

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {BaseConfig} from "@level/config/deploy/BaseConfig.sol";

/// @notice Script used to propose a timelock batch transaction on the multisig
/// @notice The script in itself does not make any changes, but prints TX data
contract Upgradev2_1 is Configurable, DeploymentUtils, Script {
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

    function setUp_(BaseConfig.Config memory _config) public {
        config = _config;

        vm.label(msg.sender, "Deployer EOA");
    }

    function runWithSetup(address newVaultManagerImpl, address newRewardsManagerImpl)
        external
        returns (address[] memory, bytes[] memory)
    {
        uint256 _chainId = vm.envUint("CHAIN_ID");
        setUp_(_chainId);

        (address[] memory targets, bytes[] memory payloads) = run(newVaultManagerImpl, newRewardsManagerImpl);

        return (targets, payloads);
    }

    function run(address newVaultManagerImpl, address newRewardsManagerImpl)
        public
        view
        returns (address[] memory, bytes[] memory)
    {
        if (newVaultManagerImpl == address(0)) {
            revert("New vault manager implementation is not set");
        }
        if (newRewardsManagerImpl == address(0)) {
            revert("New rewards manager implementation is not set");
        }
        if (address(config.levelContracts.swapManager) == address(0)) {
            revert("Swap manager is not set");
        }
        if (address(config.sparkVaults.sUsdc.oracle) == address(0)) {
            revert("Spark sUsdc oracle is not set");
        }
        if (address(config.oracles.cappedMNav) == address(0)) {
            revert("CappedMNav oracle is not set");
        }
        if (address(config.umbrellaVaults.waUsdcStakeToken.oracle) == address(0)) {
            revert("Umbrella USDC oracle is not set");
        }
        if (address(config.umbrellaVaults.waUsdtStakeToken.oracle) == address(0)) {
            revert("Umbrella USDT oracle is not set");
        }

        // ======== Old strategies required for rewards manager ========
        StrategyConfig memory aUsdcConfig = StrategyConfig({
            category: StrategyCategory.AAVEV3,
            baseCollateral: config.tokens.usdc,
            receiptToken: config.tokens.aUsdc,
            oracle: AggregatorV3Interface(0x95CCDE4C1bb3d56639d22185aa2f95EcfebD7F22),
            depositContract: address(config.periphery.aaveV3),
            withdrawContract: address(config.periphery.aaveV3),
            heartbeat: 1 days
        });

        StrategyConfig memory steakhouseUsdcConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(config.morphoVaults.steakhouseUsdc.vault)),
            oracle: config.morphoVaults.steakhouseUsdc.oracle,
            depositContract: address(config.morphoVaults.steakhouseUsdc.vault),
            withdrawContract: address(config.morphoVaults.steakhouseUsdc.vault),
            heartbeat: 1 days
        });

        StrategyConfig memory aUsdtConfig = StrategyConfig({
            category: StrategyCategory.AAVEV3,
            baseCollateral: config.tokens.usdt,
            receiptToken: config.tokens.aUsdt,
            oracle: AggregatorV3Interface(0x380adC857Cd3d0531C0821B5D52F34737C4eCDC4),
            depositContract: address(config.periphery.aaveV3),
            withdrawContract: address(config.periphery.aaveV3),
            heartbeat: 1 days
        });

        // =============================================================

        address[] memory targets = new address[](14);
        bytes[] memory payloads = new bytes[](14);

        // Upgrade vault manager proxy
        targets[0] = address(config.levelContracts.vaultManager);
        payloads[0] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.upgradeToAndCall.selector, newVaultManagerImpl, ""
        );

        // Upgrade rewards manager proxy
        targets[1] = address(config.levelContracts.rewardsManager);
        payloads[1] = abi.encodeWithSelector(
            config.levelContracts.rewardsManager.upgradeToAndCall.selector, newRewardsManagerImpl, ""
        );

        // Configure pause group for SwapManager
        PauserGuard.FunctionSig[] memory swapPauseGroup = new PauserGuard.FunctionSig[](2);
        swapPauseGroup[0] = PauserGuard.FunctionSig({
            selector: config.levelContracts.swapManager.setSwapConfig.selector,
            target: address(config.levelContracts.swapManager)
        });
        swapPauseGroup[1] = PauserGuard.FunctionSig({
            selector: config.levelContracts.swapManager.swap.selector,
            target: address(config.levelContracts.swapManager)
        });
        targets[2] = address(config.levelContracts.pauserGuard);
        payloads[2] = abi.encodeWithSelector(
            config.levelContracts.pauserGuard.configureGroup.selector, keccak256("SWAP_PAUSE"), swapPauseGroup
        );

        // Add spark strategy to vault manager
        StrategyConfig memory sUsdcConfig = StrategyConfig({
            category: StrategyCategory.SPARK,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(config.sparkVaults.sUsdc.vault)),
            oracle: config.sparkVaults.sUsdc.oracle,
            depositContract: address(config.sparkVaults.sUsdc.vault),
            withdrawContract: address(config.sparkVaults.sUsdc.vault),
            heartbeat: 1 days
        });
        targets[3] = address(config.levelContracts.vaultManager);
        payloads[3] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.addAssetStrategy.selector,
            address(config.tokens.usdc),
            address(config.sparkVaults.sUsdc.vault),
            sUsdcConfig
        );

        // Add superstate strategy to vault manager
        StrategyConfig memory ustbConfig = StrategyConfig({
            category: StrategyCategory.SUPERSTATE,
            baseCollateral: config.tokens.usdc,
            receiptToken: config.tokens.ustb,
            oracle: config.oracles.ustb,
            depositContract: address(config.tokens.ustb),
            withdrawContract: address(config.periphery.ustbRedemptionIdle),
            heartbeat: 1 days
        });
        targets[4] = address(config.levelContracts.vaultManager);
        payloads[4] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.addAssetStrategy.selector,
            address(config.tokens.usdc),
            address(config.tokens.ustb),
            ustbConfig
        );

        // Add m0 strategy to vault manager
        StrategyConfig memory mConfig = StrategyConfig({
            category: StrategyCategory.M0,
            baseCollateral: config.tokens.usdc,
            receiptToken: config.tokens.wrappedM,
            oracle: AggregatorV3Interface(address(config.oracles.cappedMNav)),
            depositContract: address(config.levelContracts.swapManager),
            withdrawContract: address(config.levelContracts.swapManager),
            heartbeat: 26 hours
        });
        targets[5] = address(config.levelContracts.vaultManager);
        payloads[5] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.addAssetStrategy.selector,
            address(config.tokens.usdc),
            address(config.tokens.wrappedM),
            mConfig
        );

        // Add Umbrella USDC strategy to vault manager
        StrategyConfig memory umbrellaUsdcConfig = StrategyConfig({
            category: StrategyCategory.AAVEV3_UMBRELLA,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(config.umbrellaVaults.waUsdcStakeToken.vault)),
            oracle: config.umbrellaVaults.waUsdcStakeToken.oracle,
            depositContract: address(config.umbrellaVaults.waUsdcStakeToken.vault),
            withdrawContract: address(config.umbrellaVaults.waUsdcStakeToken.vault),
            heartbeat: 1 days
        });
        targets[6] = address(config.levelContracts.vaultManager);
        payloads[6] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.addAssetStrategy.selector,
            address(config.tokens.usdc),
            address(config.umbrellaVaults.waUsdcStakeToken.vault),
            umbrellaUsdcConfig
        );

        // Add Umbrella USDT strategy to vault manager
        StrategyConfig memory umbrellaUsdtConfig = StrategyConfig({
            category: StrategyCategory.AAVEV3_UMBRELLA,
            baseCollateral: config.tokens.usdt,
            receiptToken: ERC20(address(config.umbrellaVaults.waUsdtStakeToken.vault)),
            oracle: config.umbrellaVaults.waUsdtStakeToken.oracle,
            depositContract: address(config.umbrellaVaults.waUsdtStakeToken.vault),
            withdrawContract: address(config.umbrellaVaults.waUsdtStakeToken.vault),
            heartbeat: 1 days
        });
        targets[7] = address(config.levelContracts.vaultManager);
        payloads[7] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.addAssetStrategy.selector,
            address(config.tokens.usdt),
            address(config.umbrellaVaults.waUsdtStakeToken.vault),
            umbrellaUsdtConfig
        );

        // Update default strategies for USDC in vault manager
        address[] memory usdcDefaultStrategies = new address[](3);
        usdcDefaultStrategies[0] = address(config.periphery.aaveV3);
        usdcDefaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        usdcDefaultStrategies[2] = address(config.sparkVaults.sUsdc.vault);
        targets[8] = address(config.levelContracts.vaultManager);
        payloads[8] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.setDefaultStrategies.selector,
            address(config.tokens.usdc),
            usdcDefaultStrategies
        );

        // Set rewards manager allStrategies for USDC
        StrategyConfig[] memory usdcConfigs = new StrategyConfig[](6);
        usdcConfigs[0] = aUsdcConfig;
        usdcConfigs[1] = steakhouseUsdcConfig;
        usdcConfigs[2] = sUsdcConfig;
        usdcConfigs[3] = ustbConfig;
        usdcConfigs[4] = mConfig;
        usdcConfigs[5] = umbrellaUsdcConfig;

        targets[9] = address(config.levelContracts.rewardsManager);
        payloads[9] = abi.encodeWithSelector(
            config.levelContracts.rewardsManager.setAllStrategies.selector, address(config.tokens.usdc), usdcConfigs
        );

        // Set rewards manager allStrategies for USDT
        StrategyConfig[] memory usdtConfigs = new StrategyConfig[](2);
        usdtConfigs[0] = aUsdtConfig;
        usdtConfigs[1] = umbrellaUsdtConfig;

        targets[10] = address(config.levelContracts.rewardsManager);
        payloads[10] = abi.encodeWithSelector(
            config.levelContracts.rewardsManager.setAllStrategies.selector, address(config.tokens.usdt), usdtConfigs
        );

        // Call umbrella modifyAaveUmbrellaCooldownOperator for USDC
        targets[11] = address(config.levelContracts.vaultManager);
        payloads[11] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.modifyAaveUmbrellaCooldownOperator.selector,
            address(config.users.operator),
            address(config.umbrellaVaults.waUsdcStakeToken.vault),
            true
        );

        // Call umbrella modifyAaveUmbrellaCooldownOperator for USDT
        targets[12] = address(config.levelContracts.vaultManager);
        payloads[12] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.modifyAaveUmbrellaCooldownOperator.selector,
            address(config.users.operator),
            address(config.umbrellaVaults.waUsdtStakeToken.vault),
            true
        );

        // Call modifyAaveUmbrellaRewardsClaimer
        targets[13] = address(config.levelContracts.vaultManager);
        payloads[13] = abi.encodeWithSelector(
            config.levelContracts.vaultManager.modifyAaveUmbrellaRewardsClaimer.selector,
            address(config.users.protocolTreasury),
            address(0x4655Ce3D625a63d30bA704087E52B4C31E38188B), // Umbrella Rewards Claimer
            true
        );

        // printScheduleJson(targets, payloads);

        return (targets, payloads);
    }

    function printScheduleJson(address[] memory targets, bytes[] memory payloads) public view {
        TimelockController timelock = config.levelContracts.adminTimelock;

        uint256[] memory values = new uint256[](targets.length);

        for (uint256 i = 0; i < targets.length; i++) {
            values[i] = 0;
        }

        bytes32 salt = keccak256("V2.1_UPGRADE");
        bytes32 predecessor = bytes32(0);
        uint256 delay = 5 days;

        bytes32 opHash = timelock.hashOperationBatch(targets, values, payloads, predecessor, salt);

        console2.log("OPERATION HASH:");
        console2.logBytes32(opHash);

        console2.log("----- COPY BELOW FOR GNOSIS SAFE JSON TRANSACTION BUILDER -----");

        console2.log("{");
        console2.log('"to": "0x%s",', string(toHex(address(timelock))));
        console2.log('"value": "0",');
        console2.log(
            '"data": "0x%s",',
            string(
                toHex(
                    abi.encodeWithSelector(
                        timelock.scheduleBatch.selector, targets, values, payloads, predecessor, salt, delay
                    )
                )
            )
        );
        console2.log('"operation": 0');
        console2.log("}");
    }

    function toHex(address addr) internal pure returns (string memory) {
        return toHex(abi.encodePacked(addr));
    }

    function toHex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}
