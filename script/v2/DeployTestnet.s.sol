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
import {ILevelMintingV2Structs} from "@level/src/v2/interfaces/level/ILevelMintingV2.sol";

/**
 * Kitchen sink deployment script; deploy the entire protocol in one go.
 * Used for testing + development.
 *
 * source .env && forge script script/v2/DeployTestnet.s.sol:DeployTestnet  --slow --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify
 */
contract DeployTestnet is Configurable, DeploymentUtils, Script {
    uint256 public chainId;

    Vm.Wallet public deployerWallet;

    StrategyConfig public steakhouseUsdcConfig;

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

        vm.label(deployerWallet.addr, "Deployer EOA");
    }

    function run() external returns (BaseConfig.Config memory) {
        return _run();
    }

    function _run() internal returns (BaseConfig.Config memory) {
        console2.log(string.concat("Deployer EOA: ", vm.toString(deployerWallet.addr)));
        if (deployerWallet.privateKey != 0) {
            vm.startBroadcast(deployerWallet.privateKey);
        } else {
            vm.startBroadcast();
        }

        deployAdminTimelock();
        deployRolesAuthority();
        deployPauserGuard();
        deployBoringVault();
        deployVaultManager();
        deployRewardsManager();
        deployLevelMintingV2();
        deployERC4626OracleFactory();
        configurePauseGroups();

        // Deploy oracles
        if (address(config.morphoVaults.steakhouseUsdc.oracle) == address(0)) {
            config.morphoVaults.steakhouseUsdc.oracle =
                deployERC4626Oracle(config.morphoVaults.steakhouseUsdc.vault, 4 hours);
        }

        steakhouseUsdcConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(config.morphoVaults.steakhouseUsdc.vault)),
            oracle: config.morphoVaults.steakhouseUsdc.oracle,
            depositContract: address(config.morphoVaults.steakhouseUsdc.vault),
            withdrawContract: address(config.morphoVaults.steakhouseUsdc.vault),
            heartbeat: 12 hours
        });

        StrategyConfig[] memory usdcConfigs = new StrategyConfig[](1);
        usdcConfigs[0] = steakhouseUsdcConfig;

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

        _setRoleIfNotExists(config.users.admin, PAUSER_ROLE);
        _setRoleIfNotExists(config.users.operator, PAUSER_ROLE);
        _setRoleIfNotExists(config.users.admin, UNPAUSER_ROLE);
        _setRoleIfNotExists(config.users.hexagateGatekeepers[0], PAUSER_ROLE);

        //--------------- Add Morpho as strategies
        if (address(config.morphoVaults.steakhouseUsdc.vault) == address(0)) {
            revert("Steakhouse USDC vaults not deployed");
        } else {
            config.levelContracts.vaultManager.addAssetStrategy(
                address(config.tokens.usdc), address(config.morphoVaults.steakhouseUsdc.vault), steakhouseUsdcConfig
            );
        }

        // Add Steakhouse as a default strategy
        address[] memory usdcDefaultStrategies = new address[](1);
        usdcDefaultStrategies[0] = address(config.morphoVaults.steakhouseUsdc.vault);

        config.levelContracts.vaultManager.setDefaultStrategies(address(config.tokens.usdc), usdcDefaultStrategies);

        // ---------- Setup RewardsManager
        _setRoleCapabilityIfNotExists(
            REWARDER_ROLE,
            address(config.levelContracts.rewardsManager),
            bytes4(abi.encodeWithSignature("reward(address[])"))
        );

        _setRoleIfNotExists(address(config.levelContracts.levelMintingV2), REWARDER_ROLE);
        _setRoleIfNotExists(address(config.users.operator), REWARDER_ROLE);

        config.levelContracts.rewardsManager.setTreasury(config.users.protocolTreasury);

        config.levelContracts.rewardsManager.setAllStrategies(address(config.tokens.usdc), usdcConfigs);

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

        _setRoleIfNotExists(config.users.admin, REDEEMER_ROLE);
        _setRoleIfNotExists(config.users.admin, GATEKEEPER_ROLE);
        _setRoleIfNotExists(config.users.admin, ADMIN_MULTISIG_ROLE);

        _setRoleIfNotExists(config.users.operator, REDEEMER_ROLE);
        _setRoleIfNotExists(config.users.operator, GATEKEEPER_ROLE);

        config.levelContracts.levelMintingV2.addMintableAsset(address(config.tokens.usdc));
        config.levelContracts.levelMintingV2.addRedeemableAsset(address(config.tokens.usdc));
        config.levelContracts.levelMintingV2.addOracle(address(config.tokens.usdc), address(config.oracles.usdc), false);

        config.levelContracts.levelMintingV2.setHeartBeat(address(config.tokens.usdc), 1 days);

        // ------------ Add base collateral
        config.levelContracts.levelMintingV2.setBaseCollateral(address(config.tokens.usdc), true);

        // _cleanUp();

        _print();
        vm.stopBroadcast();

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

        config.levelContracts.adminTimelock = new TimelockController{salt: convertNameToBytes32(LevelTimelockName)}(
            0, proposers, executors, deployerWallet.addr
        );

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
            "initialize(address,address)", deployerWallet.addr, address(config.levelContracts.pauserGuard)
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

        return config.levelContracts.rewardsManager;
    }

    function deployERC4626OracleFactory() public returns (ERC4626OracleFactory) {
        if (address(config.levelContracts.erc4626OracleFactory) != address(0)) {
            return config.levelContracts.erc4626OracleFactory;
        }

        bytes memory creationCode;

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

    function _cleanUp() internal {
        config.tokens.usdc.approve(address(config.levelContracts.boringVault), 100);
        config.levelContracts.levelMintingV2.mint(
            ILevelMintingV2Structs.Order({
                beneficiary: msg.sender,
                collateral_asset: address(config.tokens.usdc),
                collateral_amount: 2,
                lvlusd_amount: 0
            })
        );

        console2.log("LvlUSD balance: %s", config.tokens.lvlUsd.balanceOf(msg.sender));

        config.tokens.lvlUsd.approve(address(config.levelContracts.levelMintingV2), 0.0001e18);
        config.levelContracts.levelMintingV2.initiateRedeem(address(config.tokens.usdc), 0.000001e18, 0);

        console2.log("Minted %s lvlUSD", config.tokens.lvlUsd.balanceOf(msg.sender));
    }

    function _print() internal view {
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
