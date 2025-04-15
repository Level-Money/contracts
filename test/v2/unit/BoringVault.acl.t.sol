// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {Test, Vm} from "forge-std/Test.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

contract BoringVaultAclUnitTests is Utils, Configurable {
    Vm.Wallet private deployer;
    Vm.Wallet private normal;

    BoringVault public vault;

    function setUp() public {
        forkMainnet(22134385);

        deployer = vm.createWallet("deployer");
        vm.label(deployer.addr, "Deployer");
        normal = vm.createWallet("normal");
        vm.label(normal.addr, "Normal");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();
        _labelAddresses();

        vault = BoringVault(payable(address(config.levelContracts.boringVault)));

        deal(address(config.tokens.usdc), address(vault), 100e6);
        deal(address(config.tokens.usdc), address(normal.addr), 100e6);
    }

    function test_manage_succeedsIfCalledByOwner() public {
        vm.prank(address(config.levelContracts.adminTimelock));
        vault.manage(
            address(config.tokens.usdc),
            abi.encodeWithSignature("transfer(address,uint256)", address(normal.addr), 1e6),
            0
        );
    }

    function test_manage_succeedsIfCalledByManager() public {
        vm.startPrank(address(config.levelContracts.vaultManager));
        vault.manage(
            address(config.tokens.usdc),
            abi.encodeWithSignature("transfer(address,uint256)", address(normal.addr), 1e6),
            0
        );
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.rewardsManager));
        vault.manage(
            address(config.tokens.usdc),
            abi.encodeWithSignature("transfer(address,uint256)", address(normal.addr), 1e6),
            0
        );
        vm.stopPrank();
    }

    function test_manage_revertsIfNotOwnerOrManager() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vault.manage(
            address(config.tokens.usdc),
            abi.encodeWithSignature("transfer(address,uint256)", address(normal.addr), 1e6),
            0
        );
        vm.stopPrank();
    }

    function test_manageBatch_succeedsIfCalledByOwner() public {
        address[] memory targets = new address[](1);
        targets[0] = address(config.tokens.usdc);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("transfer(address,uint256)", address(normal.addr), 1e6);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        vm.prank(address(config.levelContracts.adminTimelock));
        vault.manage(targets, data, values);
    }

    function test_manageBatch_succeedsIfCalledByManager() public {
        address[] memory targets = new address[](1);
        targets[0] = address(config.tokens.usdc);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("transfer(address,uint256)", address(normal.addr), 1e6);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        vm.startPrank(address(config.levelContracts.vaultManager));
        vault.manage(targets, data, values);
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.rewardsManager));
        vault.manage(targets, data, values);
        vm.stopPrank();
    }

    function test_manageBatch_revertsIfNotOwnerOrManager() public {
        address[] memory targets = new address[](1);
        targets[0] = address(config.tokens.usdc);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("transfer(address,uint256)", address(normal.addr), 1e6);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vault.manage(targets, data, values);
        vm.stopPrank();
    }

    function test_increaseAllowance_succeedsIfCalledByOwner() public {
        vm.prank(address(config.levelContracts.adminTimelock));
        vault.increaseAllowance(address(config.tokens.usdc), address(normal.addr), 1e6);
    }

    function test_increaseAllowance_succeedsIfCalledByManager() public {
        vm.startPrank(address(config.levelContracts.vaultManager));
        vault.increaseAllowance(address(config.tokens.usdc), address(normal.addr), 1e6);
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.rewardsManager));
        vault.increaseAllowance(address(config.tokens.usdc), address(normal.addr), 1e6);
        vm.stopPrank();
    }

    function test_increaseAllowance_revertsIfNotOwnerOrManager() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vault.increaseAllowance(address(config.tokens.usdc), address(normal.addr), 1e6);
        vm.stopPrank();
    }

    function test_enter_succeedsIfCalledByOwner() public {
        deal(address(config.tokens.usdc), address(config.levelContracts.adminTimelock), 100e6);

        vm.startPrank(address(config.levelContracts.adminTimelock));
        config.tokens.usdc.approve(address(vault), 1e6);
        vault.enter(address(config.levelContracts.adminTimelock), config.tokens.usdc, 1e6, address(vault), 1e6);
        vm.stopPrank();
    }

    function test_enter_succeedsIfCalledByVaultMinter() public {
        deal(address(config.tokens.usdc), address(config.levelContracts.levelMintingV2), 100e6);

        vm.startPrank(address(config.levelContracts.levelMintingV2));
        config.tokens.usdc.approve(address(vault), 1e6);
        vault.enter(address(config.levelContracts.levelMintingV2), config.tokens.usdc, 1e6, address(vault), 1e6);
        vm.stopPrank();
    }

    function test_enter_failsIfNotOwnerOrVaultMinter() public {
        deal(address(config.tokens.usdc), address(config.levelContracts.adminTimelock), 100e6);

        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vault.enter(address(config.levelContracts.adminTimelock), config.tokens.usdc, 1e6, address(vault), 1e6);
        vm.stopPrank();
    }

    function test_exit_succeedsIfCalledByOwner() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));

        vault.exit(address(config.levelContracts.adminTimelock), config.tokens.usdc, 1e6, address(vault), 0);
        vm.stopPrank();
    }

    function test_exit_succeedsIfCalledByVaultRedeemer() public {
        vm.startPrank(address(config.levelContracts.rewardsManager));
        vault.exit(
            address(config.levelContracts.rewardsManager),
            config.tokens.usdc,
            1e6,
            address(config.levelContracts.rewardsManager),
            0
        );
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.vaultManager));
        vault.exit(
            address(config.levelContracts.vaultManager),
            config.tokens.usdc,
            1e6,
            address(config.levelContracts.vaultManager),
            0
        );
        vm.stopPrank();
    }

    function test_exit_failsIfNotOwner() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        vault.exit(address(config.levelContracts.adminTimelock), config.tokens.usdc, 1e6, address(vault), 1e6);
        vm.stopPrank();
    }

    function test_setGuard_succeedsOnlyAdmin() public {
        // Generate a new address and label it
        Vm.Wallet memory newGuard = vm.createWallet("newGuard");
        vm.label(newGuard.addr, "New Guard");

        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        vault.setGuard(newGuard.addr);
        vm.stopPrank();

        vm.startPrank(config.users.admin);
        vault.setGuard(newGuard.addr);
        vm.stopPrank();

        assertEq(address(vault.guard()), newGuard.addr);
    }
}
