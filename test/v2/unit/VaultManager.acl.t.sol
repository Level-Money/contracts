// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {Test, Vm} from "forge-std/Test.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IVaultManagerErrors} from "@level/src/v2/interfaces/level/IVaultManager.sol";
import {StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";

contract VaultManagerAclUnitTests is Utils, Configurable {
    Vm.Wallet private deployer;
    Vm.Wallet private normal;
    Vm.Wallet private strategist;

    VaultManager public vaultManager;

    address public constant DAI = 0x6b175474e89094c44dA98b95B7002f2956889026;

    StrategyConfig public strategyConfig;

    function setUp() public {
        forkMainnet(22134385);

        deployer = vm.createWallet("deployer");
        vm.label(deployer.addr, "Deployer");
        normal = vm.createWallet("normal");
        vm.label(normal.addr, "Normal");
        strategist = vm.createWallet("strategist");
        vm.label(strategist.addr, "Strategist");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();
        _labelAddresses();

        vm.startPrank(config.users.admin);
        lvlUSD _lvlUSD = lvlUSD(address(config.tokens.lvlUsd));
        _lvlUSD.setMinter(address(config.levelContracts.levelMintingV2));
        vm.stopPrank();

        address[] memory targets = new address[](1);
        targets[0] = address(config.levelContracts.rolesAuthority);

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, STRATEGIST_ROLE, true);

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        vaultManager = VaultManager(address(config.levelContracts.vaultManager));

        deal(address(config.tokens.usdc), address(config.levelContracts.boringVault), 100e6);

        deal(address(config.tokens.usdc), address(strategist.addr), 100e6);

        vm.startPrank(strategist.addr);
        config.tokens.usdc.approve(address(config.periphery.aaveV3), 100e6);
        config.periphery.aaveV3.supply(
            address(config.tokens.usdc), 100e6, address(config.levelContracts.boringVault), 0
        );
        vm.stopPrank();

        strategyConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: ERC20(DAI),
            receiptToken: ERC20(DAI),
            oracle: AggregatorV3Interface(DAI),
            depositContract: address(DAI),
            withdrawContract: address(DAI),
            heartbeat: 1 days
        });
    }

    function test_deposit_succeedsIfStrategist() public {
        vm.startPrank(strategist.addr);
        uint256 deposited = vaultManager.deposit(address(config.tokens.usdc), address(config.periphery.aaveV3), 100e6);
        vm.stopPrank();

        assertGt(deposited, 0);
    }

    function test_deposit_revertsIfNotStrategist() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.deposit(address(config.tokens.usdc), address(config.periphery.aaveV3), 100e6);
        vm.stopPrank();
    }

    function test_deposit_returnsZeroIfZeroAddress() public {
        vm.startPrank(strategist.addr);
        uint256 deposited = vaultManager.deposit(address(config.tokens.usdc), address(0), 100e6);
        vm.stopPrank();

        assertEq(deposited, 0);
    }

    function test_deposit_revertsIfInvalidStrategy() public {
        vm.startPrank(strategist.addr);
        vm.expectRevert(IVaultManagerErrors.InvalidStrategy.selector);
        vaultManager.deposit(address(config.tokens.usdc), address(0xdeadbeef), 100e6);
        vm.stopPrank();
    }

    function test_depositDefault_succeedsIfStrategist() public {
        vm.startPrank(strategist.addr);
        uint256 deposited = vaultManager.depositDefault(address(config.tokens.usdc), 100e6);
        vm.stopPrank();

        assertGt(deposited, 0);
    }

    function test_depositDefault_revertsIfNotStrategist() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.depositDefault(address(config.tokens.usdc), 100e6);
        vm.stopPrank();
    }

    function test_withdraw_succeedsIfStrategist() public {
        vm.startPrank(strategist.addr);
        uint256 withdrawn = vaultManager.withdraw(address(config.tokens.usdc), address(config.periphery.aaveV3), 99e6);
        vm.stopPrank();

        assertGt(withdrawn, 0);
    }

    function test_withdraw_returnsZeroIfZeroAddress() public {
        vm.startPrank(strategist.addr);
        uint256 withdrawn = vaultManager.withdraw(address(config.tokens.usdc), address(0), 99e6);
        vm.stopPrank();

        assertEq(withdrawn, 0);
    }

    function test_withdraw_revertsIfNotStrategist() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.withdraw(address(config.tokens.usdc), address(config.periphery.aaveV3), 99e6);
        vm.stopPrank();
    }

    function test_withdraw_revertsIfInvalidStrategy() public {
        vm.startPrank(strategist.addr);
        vm.expectRevert(IVaultManagerErrors.InvalidStrategy.selector);
        vaultManager.withdraw(address(config.tokens.usdc), address(0xdeadbeef), 99e6);
        vm.stopPrank();
    }

    function test_withdrawDefault_succeedsIfStrategist() public {
        vm.startPrank(strategist.addr);
        uint256 withdrawn = vaultManager.withdrawDefault(address(config.tokens.usdc), 99e6);
        vm.stopPrank();

        assertGt(withdrawn, 0);
    }

    function test_withdrawDefault_revertsIfNotStrategist() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.withdrawDefault(address(config.tokens.usdc), 99e6);
        vm.stopPrank();
    }

    function test_setVault_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vaultManager.setVault(address(config.levelContracts.boringVault));
        vm.stopPrank();
    }

    function test_setVault_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.setVault(address(config.levelContracts.boringVault));
        vm.stopPrank();
    }

    function test_addAssetStrategy_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(DAI), strategyConfig);
        vm.stopPrank();
    }

    function test_addAssetStrategy_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(DAI), strategyConfig);
        vm.stopPrank();
    }

    function test_addAssetStrategy_revertsIfInvalidAssetOrStrategy() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(IVaultManagerErrors.InvalidAssetOrStrategy.selector);
        vaultManager.addAssetStrategy(address(0), address(DAI), strategyConfig);
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(IVaultManagerErrors.InvalidAssetOrStrategy.selector);
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(0), strategyConfig);
        vm.stopPrank();
    }

    function test_addAssetStrategy_revertsIfAlreadyExists() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(DAI), strategyConfig);

        vm.expectRevert(IVaultManagerErrors.StrategyAlreadyExists.selector);
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(DAI), strategyConfig);
        vm.stopPrank();
    }

    function test_removeAssetStrategy_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(DAI), strategyConfig);
        vaultManager.removeAssetStrategy(address(config.tokens.usdc), address(DAI));
        vm.stopPrank();
    }

    function test_removeAssetStrategy_succeedsIfGatekeeper() public {
        vm.prank(address(config.levelContracts.adminTimelock));
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(DAI), strategyConfig);

        vm.startPrank(config.users.admin);
        vaultManager.removeAssetStrategy(address(config.tokens.usdc), address(DAI));
        vm.stopPrank();
    }

    function test_removeAssetStrategy_revertsIfNotAuthorized() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.removeAssetStrategy(address(config.tokens.usdc), address(DAI));
        vm.stopPrank();
    }

    function test_removeAssetStrategy_revertsIfStrategyDoesNotExist() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(IVaultManagerErrors.StrategyDoesNotExist.selector);
        vaultManager.removeAssetStrategy(address(config.tokens.usdc), address(DAI));
        vm.stopPrank();
    }

    function test_setDefaultStrategies_succeedsIfTimelock() public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(DAI);

        vm.startPrank(address(config.levelContracts.adminTimelock));
        vaultManager.addAssetStrategy(address(config.tokens.usdc), address(DAI), strategyConfig);

        vaultManager.setDefaultStrategies(address(config.tokens.usdc), strategies);
        vm.stopPrank();
    }

    function test_setDefaultStrategies_failsIfNoStrategies() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(IVaultManagerErrors.NoStrategiesProvided.selector);
        vaultManager.setDefaultStrategies(address(config.tokens.usdc), new address[](0));
        vm.stopPrank();
    }

    function test_setDefaultStrategies_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.setDefaultStrategies(address(config.tokens.usdc), new address[](0));
        vm.stopPrank();
    }

    function test_setDefaultStrategies_revertsIfInvalidStrategy() public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(DAI);

        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(IVaultManagerErrors.InvalidStrategy.selector);
        vaultManager.setDefaultStrategies(address(config.tokens.usdc), strategies);
        vm.stopPrank();
    }

    function test_setGuard_succeedsOnlyAdmin() public {
        // Generate a new address and label it
        Vm.Wallet memory newGuard = vm.createWallet("newGuard");
        vm.label(newGuard.addr, "New Guard");

        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        vaultManager.setGuard(newGuard.addr);
        vm.stopPrank();

        vm.startPrank(config.users.admin);
        vaultManager.setGuard(newGuard.addr);
        vm.stopPrank();

        assertEq(address(vaultManager.guard()), newGuard.addr);
    }
}
