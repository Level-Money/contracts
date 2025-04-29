// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.25;

import {RolesAuthority, Authority} from "@solmate/src/auth/authorities/RolesAuthority.sol";
import {ContractNames} from "@level/config/ContractNames.sol";
import {ContractAddresses} from "@level/config/ContractAddresses.sol";
import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {BaseConfig} from "@level/config/deploy/BaseConfig.sol";

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {AaveTokenOracle} from "@level/src/v2/oracles/AaveTokenOracle.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC4626OracleFactory} from "@level/src/v2/oracles/ERC4626OracleFactory.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {StrategyCategory, StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";
import {StrictRolesAuthority} from "@level/src/v2/auth/StrictRolesAuthority.sol";

/**
 * Kitchen sink deployment script; deploy the entire protocol in one go.
 * Used for testing + development.
 *
 * source .env && forge script script/v2/DeployLevel.s.sol:DeployLevel --slow --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify
 * @dev Optionally can change `--with-gas-price` to something more reasonable
 */
contract DeployLevel is Configurable, DeploymentUtils, Script {
    uint256 public chainId;

    Vm.Wallet public deployerWallet;

    StrategyConfig public aUsdcConfig;
    StrategyConfig public aUsdtConfig;
    StrategyConfig public steakhouseUsdcConfig;
    StrategyConfig public steakhouseUsdtConfig;
    StrategyConfig public re7UsdcConfig;
    StrategyConfig public steakhouseUsdtLiteConfig;

    function setUp() external {
        uint256 _chainId = vm.envUint("CHAIN_ID");

        setUp_(_chainId);
    }

    function setUp_(uint256 _chainId) public {
        chainId = _chainId;
        initConfig(_chainId);

        deployerWallet.addr = msg.sender;

        vm.label(deployerWallet.addr, "Deployer EOA");
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
        console2.log(string.concat("Deployer EOA: ", vm.toString(deployerWallet.addr)));

        return _run();
    }

    modifier asDeployer() {
        if (deployerWallet.privateKey != 0) {
            vm.startBroadcast(deployerWallet.privateKey);
        } else {
            vm.startBroadcast();
        }

        _;

        vm.stopBroadcast();
    }

    function _run() internal asDeployer returns (BaseConfig.Config memory) {
        // Deploy
        deployAdminTimelock();
        deployRolesAuthority();
        deployPauserGuard();
        deployBoringVault();
        deployVaultManager();
        deployRewardsManager();
        deployLevelMintingV2();
        deployERC4626OracleFactory();
        configurePauseGroups();

        AaveTokenOracle aUsdcOracle = new AaveTokenOracle(address(config.tokens.usdc));
        vm.label(address(aUsdcOracle), "AaveUsdcTokenOracle");

        AaveTokenOracle aUsdtOracle = new AaveTokenOracle(address(config.tokens.usdt));
        vm.label(address(aUsdtOracle), "AaveUsdtTokenOracle");

        // Deploy oracles
        if (address(config.morphoVaults.steakhouseUsdc.oracle) == address(0)) {
            config.morphoVaults.steakhouseUsdc.oracle =
                deployERC4626Oracle(config.morphoVaults.steakhouseUsdc.vault, 4 hours);
        }

        aUsdcConfig = StrategyConfig({
            category: StrategyCategory.AAVEV3,
            baseCollateral: config.tokens.usdc,
            receiptToken: config.tokens.aUsdc,
            oracle: AggregatorV3Interface(address(aUsdcOracle)),
            depositContract: address(config.periphery.aaveV3),
            withdrawContract: address(config.periphery.aaveV3),
            heartbeat: 1 days
        });

        aUsdtConfig = StrategyConfig({
            category: StrategyCategory.AAVEV3,
            baseCollateral: config.tokens.usdt,
            receiptToken: config.tokens.aUsdt,
            oracle: AggregatorV3Interface(address(aUsdtOracle)),
            depositContract: address(config.periphery.aaveV3),
            withdrawContract: address(config.periphery.aaveV3),
            heartbeat: 1 days
        });

        steakhouseUsdcConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(config.morphoVaults.steakhouseUsdc.vault)),
            oracle: config.morphoVaults.steakhouseUsdc.oracle,
            depositContract: address(config.morphoVaults.steakhouseUsdc.vault),
            withdrawContract: address(config.morphoVaults.steakhouseUsdc.vault),
            heartbeat: 1 days
        });

        StrategyConfig[] memory usdcConfigs = new StrategyConfig[](2);
        usdcConfigs[0] = aUsdcConfig;
        usdcConfigs[1] = steakhouseUsdcConfig;

        StrategyConfig[] memory usdtConfigs = new StrategyConfig[](1);
        usdtConfigs[0] = aUsdtConfig;

        //------------------ Setup BoringVault
        _setRoleCapabilityIfNotExists(
            VAULT_MINTER_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("enter(address,address,uint256,address,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            VAULT_REDEEMER_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("exit(address,address,uint256,address,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            VAULT_REDEEMER_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("increaseAllowance(address,address,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            VAULT_MANAGER_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("manage(address,bytes,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            VAULT_MANAGER_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("manage(address[],bytes[],uint256[])"))
        );
        _setRoleCapabilityIfNotExists(
            VAULT_MANAGER_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("increaseAllowance(address,address,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            VAULT_MANAGER_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("setBeforeTransferHook(address)"))
        );
        _setRoleCapabilityIfNotExists(
            GATEKEEPER_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("removeAssetStrategy(address,address)"))
        );

        _setRoleIfNotExists(address(config.levelContracts.vaultManager), VAULT_MANAGER_ROLE);
        _setRoleIfNotExists(address(config.levelContracts.vaultManager), VAULT_REDEEMER_ROLE);
        _setRoleIfNotExists(address(config.levelContracts.levelMintingV2), VAULT_MINTER_ROLE);
        _setRoleIfNotExists(address(config.levelContracts.levelMintingV2), VAULT_REDEEMER_ROLE);
        _setRoleIfNotExists(address(config.levelContracts.rewardsManager), VAULT_MANAGER_ROLE);
        _setRoleIfNotExists(address(config.levelContracts.rewardsManager), VAULT_REDEEMER_ROLE);

        //----------------- Setup VaultManager
        _setRoleCapabilityIfNotExists(
            STRATEGIST_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("deposit(address,address,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            STRATEGIST_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("withdraw(address,address,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            STRATEGIST_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("depositDefault(address,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            STRATEGIST_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("withdrawDefault(address,uint256)"))
        );

        _setRoleIfNotExists(address(config.levelContracts.levelMintingV2), STRATEGIST_ROLE);
        _setRoleIfNotExists(address(config.users.operator), STRATEGIST_ROLE);

        config.levelContracts.vaultManager.setVault(address(config.levelContracts.boringVault));

        // --------------- Setup PauserGuard
        _setRoleCapabilityIfNotExists(
            PAUSER_ROLE,
            address(config.levelContracts.pauserGuard),
            bytes4(abi.encodeWithSignature("pauseGroup(bytes32)"))
        );

        _setRoleCapabilityIfNotExists(
            UNPAUSER_ROLE,
            address(config.levelContracts.pauserGuard),
            bytes4(abi.encodeWithSignature("unpauseGroup(bytes32)"))
        );

        _setRoleCapabilityIfNotExists(
            PAUSER_ROLE,
            address(config.levelContracts.pauserGuard),
            bytes4(abi.encodeWithSignature("pauseSelector(address,bytes4)"))
        );

        _setRoleCapabilityIfNotExists(
            UNPAUSER_ROLE,
            address(config.levelContracts.pauserGuard),
            bytes4(abi.encodeWithSignature("unpauseSelector(address,bytes4)"))
        );

        _setRoleCapabilityIfNotExists(
            ADMIN_MULTISIG_ROLE,
            address(config.levelContracts.levelMintingV2),
            bytes4(abi.encodeWithSignature("setGuard(address)"))
        );

        _setRoleCapabilityIfNotExists(
            ADMIN_MULTISIG_ROLE,
            address(config.levelContracts.vaultManager),
            bytes4(abi.encodeWithSignature("setGuard(address)"))
        );

        _setRoleCapabilityIfNotExists(
            ADMIN_MULTISIG_ROLE,
            address(config.levelContracts.boringVault),
            bytes4(abi.encodeWithSignature("setGuard(address)"))
        );

        _setRoleCapabilityIfNotExists(
            ADMIN_MULTISIG_ROLE,
            address(config.levelContracts.rewardsManager),
            bytes4(abi.encodeWithSignature("setGuard(address)"))
        );

        _setRoleIfNotExists(config.users.admin, PAUSER_ROLE);
        _setRoleIfNotExists(config.users.operator, PAUSER_ROLE);
        _setRoleIfNotExists(config.users.admin, UNPAUSER_ROLE);
        _setRoleIfNotExists(config.users.hexagateGatekeepers[0], PAUSER_ROLE);
        _setRoleIfNotExists(config.users.hexagateGatekeepers[1], PAUSER_ROLE);

        //------------- Add Aave as a strategy
        config.levelContracts.vaultManager.addAssetStrategy(
            address(config.tokens.usdc), address(config.periphery.aaveV3), aUsdcConfig
        );

        config.levelContracts.vaultManager.addAssetStrategy(
            address(config.tokens.usdt), address(config.periphery.aaveV3), aUsdtConfig
        );

        //--------------- Add Morpho as strategies
        if (address(config.morphoVaults.steakhouseUsdc.vault) == address(0)) {
            revert("Steakhouse USDC vaults not deployed");
        } else {
            config.levelContracts.vaultManager.addAssetStrategy(
                address(config.tokens.usdc), address(config.morphoVaults.steakhouseUsdc.vault), steakhouseUsdcConfig
            );
        }

        // Add Aave as a default strategy
        address[] memory usdcDefaultStrategies = new address[](2);
        usdcDefaultStrategies[0] = address(config.periphery.aaveV3);
        usdcDefaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);

        address[] memory usdtDefaultStrategies = new address[](1);
        usdtDefaultStrategies[0] = address(config.periphery.aaveV3);

        config.levelContracts.vaultManager.setDefaultStrategies(address(config.tokens.usdc), usdcDefaultStrategies);
        config.levelContracts.vaultManager.setDefaultStrategies(address(config.tokens.usdt), usdtDefaultStrategies);

        // ---------- Setup RewardsManager
        _setRoleCapabilityIfNotExists(
            REWARDER_ROLE,
            address(config.levelContracts.rewardsManager),
            bytes4(abi.encodeWithSignature("reward(address,uint256)"))
        );

        _setRoleIfNotExists(address(config.levelContracts.levelMintingV2), REWARDER_ROLE);
        _setRoleIfNotExists(address(config.users.operator), REWARDER_ROLE);

        config.levelContracts.rewardsManager.setTreasury(config.users.protocolTreasury);

        address[] memory baseCollateral = new address[](2);
        baseCollateral[0] = address(config.tokens.usdc);
        baseCollateral[1] = address(config.tokens.usdt);
        config.levelContracts.rewardsManager.setAllBaseCollateral(baseCollateral);

        config.levelContracts.rewardsManager.setAllStrategies(address(config.tokens.usdc), usdcConfigs);
        config.levelContracts.rewardsManager.setAllStrategies(address(config.tokens.usdt), usdtConfigs);

        // ---------- Setup LevelMintingV2
        config.levelContracts.rolesAuthority.setPublicCapability(
            address(config.levelContracts.levelMintingV2),
            bytes4(config.levelContracts.levelMintingV2.mint.selector),
            true
        );

        _setRoleCapabilityIfNotExists(
            REDEEMER_ROLE,
            address(config.levelContracts.levelMintingV2),
            bytes4(abi.encodeWithSignature("initiateRedeem(address,uint256,uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            GATEKEEPER_ROLE,
            address(config.levelContracts.levelMintingV2),
            bytes4(abi.encodeWithSignature("setMaxMintPerBlock(uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            GATEKEEPER_ROLE,
            address(config.levelContracts.levelMintingV2),
            bytes4(abi.encodeWithSignature("setMaxRedeemPerBlock(uint256)"))
        );
        _setRoleCapabilityIfNotExists(
            GATEKEEPER_ROLE,
            address(config.levelContracts.levelMintingV2),
            bytes4(abi.encodeWithSignature("disableMintRedeem()"))
        );
        _setRoleCapabilityIfNotExists(
            ADMIN_MULTISIG_ROLE,
            address(config.levelContracts.levelMintingV2),
            bytes4(abi.encodeWithSignature("removeMintableAsset(address)"))
        );
        _setRoleCapabilityIfNotExists(
            ADMIN_MULTISIG_ROLE,
            address(config.levelContracts.levelMintingV2),
            bytes4(abi.encodeWithSignature("removeRedeemableAsset(address)"))
        );

        config.levelContracts.levelMintingV2.addMintableAsset(address(config.tokens.usdc));
        config.levelContracts.levelMintingV2.addMintableAsset(address(config.tokens.usdt));
        config.levelContracts.levelMintingV2.addMintableAsset(address(config.tokens.aUsdc));
        config.levelContracts.levelMintingV2.addMintableAsset(address(config.tokens.aUsdt));
        config.levelContracts.levelMintingV2.addMintableAsset(address(config.morphoVaults.steakhouseUsdc.vault));

        config.levelContracts.levelMintingV2.addRedeemableAsset(address(config.tokens.usdc));
        config.levelContracts.levelMintingV2.addRedeemableAsset(address(config.tokens.usdt));

        config.levelContracts.levelMintingV2.addOracle(address(config.tokens.usdc), address(config.oracles.usdc), false);
        config.levelContracts.levelMintingV2.addOracle(address(config.tokens.usdt), address(config.oracles.usdt), false);
        config.levelContracts.levelMintingV2.addOracle(address(config.tokens.aUsdc), address(aUsdcOracle), false);
        config.levelContracts.levelMintingV2.addOracle(address(config.tokens.aUsdt), address(aUsdtOracle), false);
        config.levelContracts.levelMintingV2.addOracle(
            address(config.morphoVaults.steakhouseUsdc.vault), address(config.morphoVaults.steakhouseUsdc.oracle), true
        );

        config.levelContracts.levelMintingV2.setHeartBeat(address(config.tokens.usdc), 1 days);
        config.levelContracts.levelMintingV2.setHeartBeat(address(config.tokens.usdt), 1 days);
        config.levelContracts.levelMintingV2.setHeartBeat(address(config.tokens.aUsdc), 1 days);
        config.levelContracts.levelMintingV2.setHeartBeat(address(config.tokens.aUsdt), 1 days);
        config.levelContracts.levelMintingV2.setHeartBeat(address(config.morphoVaults.steakhouseUsdc.vault), 4 hours);

        config.levelContracts.levelMintingV2.setCooldownDuration(5 minutes);

        // ------------ Setup StrictRolesAuthority
        _setRoleCapabilityIfNotExists(
            ADMIN_MULTISIG_ROLE,
            address(config.levelContracts.rolesAuthority),
            bytes4(abi.encodeWithSignature("removeUserRole(address,uint8)"))
        );
        config.levelContracts.rolesAuthority.setRoleRemovable(PAUSER_ROLE, true);
        config.levelContracts.rolesAuthority.setRoleRemovable(GATEKEEPER_ROLE, true);
        config.levelContracts.rolesAuthority.setRoleRemovable(REDEEMER_ROLE, true);
        config.levelContracts.rolesAuthority.setRoleRemovable(MINTER_ROLE, true);

        _setRoleIfNotExists(config.users.admin, REDEEMER_ROLE);
        _setRoleIfNotExists(config.users.admin, GATEKEEPER_ROLE);
        _setRoleIfNotExists(config.users.admin, ADMIN_MULTISIG_ROLE);

        _setRoleIfNotExists(config.users.operator, REDEEMER_ROLE);
        _setRoleIfNotExists(config.users.operator, GATEKEEPER_ROLE);

        // ------------ Add base collateral
        config.levelContracts.levelMintingV2.setBaseCollateral(address(config.tokens.usdc), true);
        config.levelContracts.levelMintingV2.setBaseCollateral(address(config.tokens.usdt), true);

        _addExistingRedeemers();

        cleanUp();

        return config;
    }

    function deployRolesAuthority() public returns (StrictRolesAuthority) {
        if (address(config.levelContracts.rolesAuthority) != address(0)) {
            return config.levelContracts.rolesAuthority;
        }

        config.levelContracts.rolesAuthority = new StrictRolesAuthority{
            salt: convertNameToBytes32(LevelUsdReserveRolesAuthorityName)
        }(deployerWallet.addr, Authority(address(0)));

        vm.label(address(config.levelContracts.rolesAuthority), LevelUsdReserveRolesAuthorityName);

        // Need to set the authority of the roles authority to itself
        config.levelContracts.rolesAuthority.setAuthority(config.levelContracts.rolesAuthority);

        return config.levelContracts.rolesAuthority;
    }

    function deployAdminTimelock() public returns (TimelockController) {
        if (address(config.levelContracts.adminTimelock) != address(0)) {
            return config.levelContracts.adminTimelock;
        }

        address[] memory proposers = new address[](1);
        proposers[0] = address(config.users.admin);

        address[] memory executors = new address[](1);
        executors[0] = address(config.users.admin);

        config.levelContracts.adminTimelock =
            new TimelockController{salt: convertNameToBytes32(LevelTimelockName)}(0, proposers, executors, address(0));

        vm.label(address(config.levelContracts.adminTimelock), LevelTimelockName);
        return config.levelContracts.adminTimelock;
    }

    function deployBoringVault() public returns (BoringVault) {
        if (address(config.levelContracts.boringVault) != address(0)) {
            return config.levelContracts.boringVault;
        }

        if (address(config.levelContracts.rolesAuthority) == address(0)) {
            revert("RolesAuthority must be deployed first");
        }

        if (address(config.levelContracts.pauserGuard) == address(0)) {
            revert("PauserGuard must be deployed first");
        }

        BoringVault _boringVault = new BoringVault{salt: convertNameToBytes32(LevelUsdReserveName)}(
            deployerWallet.addr, "Level Vault Shares", "lvlVault", 18, address(config.levelContracts.pauserGuard)
        );

        _boringVault.setAuthority(config.levelContracts.rolesAuthority);

        vm.label(address(_boringVault), LevelUsdReserveName);

        config.levelContracts.boringVault = _boringVault;
        return _boringVault;
    }

    function deployVaultManager() public returns (VaultManager) {
        if (address(config.levelContracts.vaultManager) != address(0)) {
            return config.levelContracts.vaultManager;
        }

        if (address(config.levelContracts.boringVault) == address(0)) {
            revert("BoringVault must be deployed first");
        }

        if (address(config.levelContracts.rolesAuthority) == address(0)) {
            revert("RolesAuthority must be deployed first");
        }

        if (address(config.levelContracts.pauserGuard) == address(0)) {
            revert("PauserGuard must be deployed first");
        }

        bytes memory constructorArgs = abi.encodeWithSignature(
            "initialize(address,address,address)",
            deployerWallet.addr,
            address(config.levelContracts.pauserGuard),
            address(config.levelContracts.boringVault)
        );

        VaultManager _vaultManager = new VaultManager{salt: convertNameToBytes32(LevelUsdReserveManagerName)}();
        ERC1967Proxy _vaultManagerProxy = new ERC1967Proxy{salt: convertNameToBytes32(LevelUsdReserveManagerName)}(
            address(_vaultManager), constructorArgs
        );

        vm.label(address(_vaultManagerProxy), LevelUsdReserveManagerName);

        config.levelContracts.vaultManager = VaultManager(address(_vaultManagerProxy));

        config.levelContracts.vaultManager.setAuthority(config.levelContracts.rolesAuthority);
        return config.levelContracts.vaultManager;
    }

    function deployRewardsManager() public returns (RewardsManager) {
        if (address(config.levelContracts.rewardsManager) != address(0)) {
            return config.levelContracts.rewardsManager;
        }

        if (address(config.levelContracts.boringVault) == address(0)) {
            revert("BoringVault must be deployed first");
        }

        if (address(config.levelContracts.rolesAuthority) == address(0)) {
            revert("RolesAuthority must be deployed first");
        }

        if (address(config.levelContracts.pauserGuard) == address(0)) {
            revert("PauserGuard must be deployed first");
        }

        bytes memory constructorArgs = abi.encodeWithSignature(
            "initialize(address,address,address)",
            deployerWallet.addr,
            address(config.levelContracts.boringVault),
            address(config.levelContracts.pauserGuard)
        );
        RewardsManager _rewardsManager = new RewardsManager{salt: convertNameToBytes32(LevelUsdRewardsManagerName)}();
        ERC1967Proxy _rewardsManagerProxy = new ERC1967Proxy{salt: convertNameToBytes32(LevelUsdRewardsManagerName)}(
            address(_rewardsManager), constructorArgs
        );

        vm.label(address(_rewardsManagerProxy), LevelUsdRewardsManagerName);

        config.levelContracts.rewardsManager = RewardsManager(address(_rewardsManagerProxy));

        config.levelContracts.rewardsManager.setAuthority(config.levelContracts.rolesAuthority);

        config.levelContracts.rewardsManager.updateOracle(address(config.tokens.usdc), address(config.oracles.usdc));
        config.levelContracts.rewardsManager.updateOracle(address(config.tokens.usdt), address(config.oracles.usdt));

        return config.levelContracts.rewardsManager;
    }

    function deployERC4626OracleFactory() public returns (ERC4626OracleFactory) {
        if (address(config.levelContracts.erc4626OracleFactory) != address(0)) {
            return config.levelContracts.erc4626OracleFactory;
        }

        ERC4626OracleFactory _erc4626OracleFactory =
            new ERC4626OracleFactory{salt: convertNameToBytes32(LevelERC4626OracleFactoryName)}();

        vm.label(address(_erc4626OracleFactory), LevelERC4626OracleFactoryName);

        config.levelContracts.erc4626OracleFactory = ERC4626OracleFactory(address(_erc4626OracleFactory));
        return config.levelContracts.erc4626OracleFactory;
    }

    function deployERC4626Oracle(IERC4626 vault, uint256 delay) public returns (IERC4626Oracle) {
        if (address(config.levelContracts.erc4626OracleFactory) == address(0)) {
            revert("ERC4626OracleFactory must be deployed first");
        }

        IERC4626Oracle _erc4626Oracle = IERC4626Oracle(config.levelContracts.erc4626OracleFactory.create(vault));
        vm.label(address(_erc4626Oracle), string.concat(vault.name(), " Oracle"));

        return _erc4626Oracle;
    }

    function deployLevelMintingV2() public returns (LevelMintingV2) {
        if (address(config.levelContracts.levelMintingV2) != address(0)) {
            return config.levelContracts.levelMintingV2;
        }

        if (address(config.levelContracts.boringVault) == address(0)) {
            revert("BoringVault must be deployed first");
        }

        if (address(config.levelContracts.rolesAuthority) == address(0)) {
            revert("RolesAuthority must be deployed first");
        }

        if (address(config.levelContracts.vaultManager) == address(0)) {
            revert("VaultManager must be deployed first");
        }

        if (address(config.levelContracts.pauserGuard) == address(0)) {
            revert("PauserGuard must be deployed first");
        }

        bytes memory constructorArgs = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,address,address,address)",
            address(deployerWallet.addr),
            500000e18,
            250000e18,
            address(config.levelContracts.rolesAuthority),
            address(config.levelContracts.vaultManager),
            address(config.levelContracts.pauserGuard)
        );

        LevelMintingV2 _levelMintingV2Impl = new LevelMintingV2{salt: convertNameToBytes32(LevelMintingName)}();
        ERC1967Proxy _levelMintingV2Proxy = new ERC1967Proxy{salt: convertNameToBytes32(LevelMintingName)}(
            address(_levelMintingV2Impl), constructorArgs
        );

        vm.label(address(_levelMintingV2Proxy), LevelMintingName);

        LevelMintingV2 _levelMintingV2 = LevelMintingV2(address(_levelMintingV2Proxy));

        vm.label(address(_levelMintingV2.silo()), "LevelMintingV2Silo");

        config.levelContracts.levelMintingV2 = _levelMintingV2;

        return _levelMintingV2;
    }

    function deployPauserGuard() public returns (PauserGuard) {
        if (address(config.levelContracts.pauserGuard) != address(0)) {
            return config.levelContracts.pauserGuard;
        }

        if (address(config.levelContracts.rolesAuthority) == address(0)) {
            revert("RolesAuthority must be deployed first");
        }

        config.levelContracts.pauserGuard = new PauserGuard{salt: convertNameToBytes32(LevelPauserGuardName)}(
            deployerWallet.addr, config.levelContracts.rolesAuthority
        );

        vm.label(address(config.levelContracts.pauserGuard), LevelPauserGuardName);

        return config.levelContracts.pauserGuard;
    }

    function configurePauseGroups() public {
        if (address(config.levelContracts.pauserGuard) == address(0)) {
            revert("PauserGuard must be deployed first");
        }

        if (address(config.levelContracts.levelMintingV2) == address(0)) {
            revert("LevelMintingV2 must be deployed first");
        }

        if (address(config.levelContracts.vaultManager) == address(0)) {
            revert("VaultManager must be deployed first");
        }

        if (address(config.levelContracts.boringVault) == address(0)) {
            revert("BoringVault must be deployed first");
        }

        // =============================== LEVEL MINTING V2 ===============================

        // Configure emergency pause group for LevelMintingV2
        PauserGuard.FunctionSig[] memory emergencyPauseGroup = new PauserGuard.FunctionSig[](3);
        emergencyPauseGroup[0] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("mint((address,address,uint256,uint256))")),
            target: address(config.levelContracts.levelMintingV2)
        });
        emergencyPauseGroup[1] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("initiateRedeem(address,uint256,uint256)")),
            target: address(config.levelContracts.levelMintingV2)
        });
        emergencyPauseGroup[2] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("completeRedeem(address,address)")),
            target: address(config.levelContracts.levelMintingV2)
        });

        config.levelContracts.pauserGuard.configureGroup(keccak256("EMERGENCY_PAUSE"), emergencyPauseGroup);

        // Configure redeem pause group for LevelMintingV2
        PauserGuard.FunctionSig[] memory redeemPauseGroup = new PauserGuard.FunctionSig[](2);
        redeemPauseGroup[0] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("completeRedeem(address,address)")),
            target: address(config.levelContracts.levelMintingV2)
        });
        redeemPauseGroup[1] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("initiateRedeem(address,uint256,uint256)")),
            target: address(config.levelContracts.levelMintingV2)
        });

        config.levelContracts.pauserGuard.configureGroup(keccak256("REDEEM_PAUSE"), redeemPauseGroup);

        // =============================== VAULT MANAGER ===============================

        // Configure emergency pause group for VaultManager
        PauserGuard.FunctionSig[] memory vaultManagerPauseGroup = new PauserGuard.FunctionSig[](4);
        vaultManagerPauseGroup[0] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("deposit(address,address,uint256)")),
            target: address(config.levelContracts.vaultManager)
        });
        vaultManagerPauseGroup[1] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("withdraw(address,address,uint256)")),
            target: address(config.levelContracts.vaultManager)
        });
        vaultManagerPauseGroup[2] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("depositDefault(address,uint256)")),
            target: address(config.levelContracts.vaultManager)
        });
        vaultManagerPauseGroup[3] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("withdrawDefault(address,uint256)")),
            target: address(config.levelContracts.vaultManager)
        });

        config.levelContracts.pauserGuard.configureGroup(keccak256("VAULT_MANAGER_PAUSE"), vaultManagerPauseGroup);

        // =============================== BORING VAULT ===============================

        PauserGuard.FunctionSig[] memory boringVaultPauseGroup = new PauserGuard.FunctionSig[](6);
        boringVaultPauseGroup[0] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("manage(address,bytes,uint256)")),
            target: address(config.levelContracts.boringVault)
        });
        boringVaultPauseGroup[1] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("manage(address[],bytes[],uint256[])")),
            target: address(config.levelContracts.boringVault)
        });
        boringVaultPauseGroup[2] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("enter(address,address,uint256,address,uint256)")),
            target: address(config.levelContracts.boringVault)
        });
        boringVaultPauseGroup[3] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("exit(address,address,uint256,address,uint256)")),
            target: address(config.levelContracts.boringVault)
        });
        boringVaultPauseGroup[4] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("increaseAllowance(address,address,uint256)")),
            target: address(config.levelContracts.boringVault)
        });
        boringVaultPauseGroup[5] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("setBeforeTransferHook(address)")),
            target: address(config.levelContracts.boringVault)
        });

        config.levelContracts.pauserGuard.configureGroup(keccak256("BORING_VAULT_PAUSE"), boringVaultPauseGroup);

        // =============================== REWARDS MANAGER ===============================

        PauserGuard.FunctionSig[] memory rewardsManagerPauseGroup = new PauserGuard.FunctionSig[](6);
        rewardsManagerPauseGroup[0] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("reward(address,uint256)")),
            target: address(config.levelContracts.rewardsManager)
        });
        rewardsManagerPauseGroup[1] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("setVault(address)")),
            target: address(config.levelContracts.rewardsManager)
        });
        rewardsManagerPauseGroup[2] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("setTreasury(address)")),
            target: address(config.levelContracts.rewardsManager)
        });
        rewardsManagerPauseGroup[3] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("setAllStrategies(address,StrategyConfig[])")),
            target: address(config.levelContracts.rewardsManager)
        });
        rewardsManagerPauseGroup[4] = PauserGuard.FunctionSig({
            selector: bytes4(abi.encodeWithSignature("setAllBaseCollateral(address[])")),
            target: address(config.levelContracts.rewardsManager)
        });

        config.levelContracts.pauserGuard.configureGroup(keccak256("REWARDS_MANAGER_PAUSE"), rewardsManagerPauseGroup);
    }

    function _setRoleIfNotExists(address user, uint8 role) internal {
        if (!config.levelContracts.rolesAuthority.doesUserHaveRole(user, role)) {
            config.levelContracts.rolesAuthority.setUserRole(user, role, true);
        }
    }

    function _setRoleCapabilityIfNotExists(uint8 role, address contractAddress, bytes4 selector) internal {
        if (!config.levelContracts.rolesAuthority.doesRoleHaveCapability(role, contractAddress, selector)) {
            config.levelContracts.rolesAuthority.setRoleCapability(role, contractAddress, selector, true);
        }
    }

    function _addExistingRedeemers() internal {
        address[24] memory redeemers = [
            0xABFD9948933b975Ee9a668a57C776eCf73F6D840,
            0xf641388a346976215B20cE3d5d3edCaBC8B9b98a,
            0xe9AF0428143E4509df4379Bd10C4850b223F2EcB,
            0xa0D26cD3Dfbe4d8edf9f95BD9129D5f733A9D9a7,
            0x5788817BcF6482da4E434e1CEF68E6f85a690b58,
            0x6fA5d361Ab8165347F636217001E22a7cEF09B48,
            0x3D3eb99C278C7A50d8cf5fE7eBF0AD69066Fb7d1,
            0xa58627a29bb59743cE1D781B1072c59bb1dda86d,
            0xE0b7DEab801D864650DEc58CbD1b3c441D058C79,
            0xaebb8FDBD5E52F99630cEBB80D0a1c19892EB4C2,
            0x562BCF627F8dD07E0bC71f82f6fCB60737f87E07,
            0x3be3A8613dC18554a73773a5Bfb8E9819d360Dc0,
            0x5bB2719f3282EC4EA21DC2D8d790c9eA6581F3D7,
            0x48035c02b450d24D8d8953Bc1A0B6C53571bA665,
            0xd7583E3CF08bbcaB66F1242195227bBf9F865Fda,
            0xbc0f3B23930fff9f4894914bD745ABAbA9588265,
            0x79B94C17d8178689Df8d10754d7e4A1Bb3D49bc1,
            0x7FE4b2632f5AE6d930677D662AF26Bc0a06672b3,
            0x79720266dEC914247424aeb0F06b8Fa5B3Ec073E,
            0xC69381073814920D1CE2BB009ac9982A74679814,
            0x10FB797CD3d8dEf7c704f54b6eBAD315F6dBa6F2,
            0x560244D3151245B85A1eDD0c4574A689D22FD275,
            0x8bBe46a0Bb587d6363cF34E655108dCB4d671E9E,
            0x2C8Cff30Fe93BaD408D20B702934E18F0bbC7eF5
        ];

        for (uint256 i = 0; i < redeemers.length; i++) {
            _setRoleIfNotExists(redeemers[i], REDEEMER_ROLE);
        }
    }

    function cleanUp() public {
        // Set the timelock as the admin of all contracts

        if (config.levelContracts.rolesAuthority.owner() == deployerWallet.addr) {
            config.levelContracts.rolesAuthority.transferOwnership(address(config.levelContracts.adminTimelock));
        }

        if (config.levelContracts.boringVault.owner() == deployerWallet.addr) {
            config.levelContracts.boringVault.transferOwnership(address(config.levelContracts.adminTimelock));
        }

        if (config.levelContracts.vaultManager.owner() == deployerWallet.addr) {
            config.levelContracts.vaultManager.transferOwnership(address(config.levelContracts.adminTimelock));
        }

        if (config.levelContracts.rewardsManager.owner() == deployerWallet.addr) {
            config.levelContracts.rewardsManager.transferOwnership(address(config.levelContracts.adminTimelock));
        }

        if (config.levelContracts.levelMintingV2.owner() == deployerWallet.addr) {
            config.levelContracts.levelMintingV2.transferOwnership(address(config.levelContracts.adminTimelock));
        }

        if (config.levelContracts.pauserGuard.owner() == deployerWallet.addr) {
            config.levelContracts.pauserGuard.transferOwnership(address(config.levelContracts.adminTimelock));
        }

        if (
            config.levelContracts.adminTimelock.hasRole(
                config.levelContracts.adminTimelock.DEFAULT_ADMIN_ROLE(), deployerWallet.addr
            )
        ) {
            config.levelContracts.adminTimelock.renounceRole(
                config.levelContracts.adminTimelock.DEFAULT_ADMIN_ROLE(), deployerWallet.addr
            );
        }
    }

    function onDeploy() public view {
        _printDeployedContracts(chainId, LevelTimelockName, address(config.levelContracts.adminTimelock));
        _printDeployedContracts(
            chainId, LevelUsdReserveRolesAuthorityName, address(config.levelContracts.rolesAuthority)
        );
        _printDeployedContracts(chainId, LevelUsdReserveName, address(config.levelContracts.boringVault));
        _printDeployedContracts(chainId, LevelUsdReserveManagerName, address(config.levelContracts.vaultManager));
        _printDeployedContracts(chainId, LevelUsdRewardsManagerName, address(config.levelContracts.rewardsManager));
        _printDeployedContracts(chainId, LevelMintingName, address(config.levelContracts.levelMintingV2));
        _printDeployedContracts(chainId, LevelPauserGuardName, address(config.levelContracts.pauserGuard));
        _printDeployedContracts(
            chainId, LevelERC4626OracleFactoryName, address(config.levelContracts.erc4626OracleFactory)
        );
    }

    // Exclude from coverage
    function test() public override {}
}
