// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test, Vm} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {StrictRolesAuthority} from "@level/src/v2/auth/StrictRolesAuthority.sol";
import {RolesAuthority} from "@solmate/src/auth/authorities/RolesAuthority.sol";
import {Auth, Authority} from "@solmate/src/auth/Auth.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";

contract StrictRolesAuthorityTest is Test, Utils, Configurable {
    Vm.Wallet public owner; // Initial deployer
    Vm.Wallet public user1; // User with roles
    Vm.Wallet public user2; // User with roles

    function setUp() public {
        forkMainnet(22305203);

        // Create wallets
        owner = vm.createWallet("owner");
        vm.label(owner.addr, "owner");
        user1 = vm.createWallet("user1");
        vm.label(user1.addr, "user1");
        user2 = vm.createWallet("user2");
        vm.label(user2.addr, "user2");

        // Deploy protocol
        DeployLevel deployScript = new DeployLevel();
        vm.prank(owner.addr);
        deployScript.setUp_(1, owner.privateKey);
        config = deployScript.run();

        // Configure roles through admin timelock
        address[] memory targets = new address[](3);
        bytes[] memory payloads = new bytes[](3);

        // Set up user1 roles
        targets[1] = address(config.levelContracts.rolesAuthority);
        payloads[1] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", user1.addr, PAUSER_ROLE, true);

        // Set up user2 roles
        targets[2] = address(config.levelContracts.rolesAuthority);
        payloads[2] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", user2.addr, UNPAUSER_ROLE, true);

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );
    }

    function test_OnlyTLCanConfigureRoles() public {
        // Test that regular users can't configure roles
        vm.startPrank(user1.addr);
        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.rolesAuthority.setRoleRemovable(PAUSER_ROLE, true);
        vm.stopPrank();

        // Test that even admin can't configure roles
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.rolesAuthority.setRoleRemovable(PAUSER_ROLE, true);
        vm.stopPrank();

        // Configure role through timelock
        address[] memory targets = new address[](1);
        bytes[] memory payloads = new bytes[](1);

        // Target should be the rolesAuthority, not the timelock
        targets[0] = address(config.levelContracts.rolesAuthority);
        payloads[0] = abi.encodeWithSignature("setRoleRemovable(uint8,bool)", PAUSER_ROLE, true);

        // Schedule and execute the admin action
        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        // Verify the role is now removable
        assertTrue(config.levelContracts.rolesAuthority.isRoleRemovable(PAUSER_ROLE));
    }

    function test_authorityOfFunctions() public {
        // The authority of rolesAuthority should be itself
        // because it stores the ADMIN_MULTISIG_ROLE -> removeUserRole capability
        assertEq(
            address(config.levelContracts.rolesAuthority.authority()), address(config.levelContracts.rolesAuthority)
        );

        // ADMIN_MULTISIG_ROLE should have removeUserRole capability
        assertTrue(
            config.levelContracts.rolesAuthority.doesRoleHaveCapability(
                ADMIN_MULTISIG_ROLE,
                address(config.levelContracts.rolesAuthority),
                bytes4(abi.encodeWithSignature("removeUserRole(address,uint8)"))
            )
        );

        // config.users.admin should have ADMIN_MULTISIG_ROLE
        assertTrue(config.levelContracts.rolesAuthority.doesUserHaveRole(config.users.admin, ADMIN_MULTISIG_ROLE));

        // config.users.admin should be able to call removeUserRole
        assertTrue(
            config.levelContracts.rolesAuthority.canCall(
                config.users.admin,
                address(config.levelContracts.rolesAuthority),
                bytes4(abi.encodeWithSignature("removeUserRole(address,uint8)"))
            )
        );

        // Check if the capability is public for this function on the rolesAuthority contract
        bool isPublic = config.levelContracts.rolesAuthority.isCapabilityPublic(
            address(config.levelContracts.rolesAuthority), config.levelContracts.rolesAuthority.removeUserRole.selector
        );

        // Assert that it's not public
        assertFalse(isPublic, "removeUserRole should not be a public capability");

        // other users should not be able to call removeUserRole
        assertFalse(
            config.levelContracts.rolesAuthority.canCall(
                user1.addr,
                address(config.levelContracts.rolesAuthority),
                bytes4(abi.encodeWithSignature("removeUserRole(address,uint8)"))
            ),
            "user1 should not be able to call removeUserRole"
        );
    }

    function test_AdminCanRemoveRoles() public {
        // Configure role through timelock
        address[] memory targets = new address[](1);
        bytes[] memory payloads = new bytes[](1);

        // Target should be the rolesAuthority, not the timelock
        targets[0] = address(config.levelContracts.rolesAuthority);
        payloads[0] = abi.encodeWithSignature("setRoleRemovable(uint8,bool)", UNPAUSER_ROLE, true);

        // UNPAUSER_ROLE should not be removable by default
        assertFalse(config.levelContracts.rolesAuthority.isRoleRemovable(UNPAUSER_ROLE));

        // Even admin can't remove a role that is not removable
        vm.startPrank(config.users.admin);
        vm.expectRevert(StrictRolesAuthority.RoleRemovalNotAllowed.selector);
        config.levelContracts.rolesAuthority.removeUserRole(user2.addr, UNPAUSER_ROLE);
        vm.stopPrank();

        // Schedule and execute the admin action
        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        // Verify the role is now removable
        assertTrue(config.levelContracts.rolesAuthority.isRoleRemovable(UNPAUSER_ROLE));

        // User 2 should have the role
        assertTrue(config.levelContracts.rolesAuthority.doesUserHaveRole(user2.addr, UNPAUSER_ROLE));

        // User 1 should not be able to remove the role
        vm.startPrank(user1.addr);
        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.rolesAuthority.removeUserRole(user2.addr, UNPAUSER_ROLE);
        vm.stopPrank();

        // admin should be able to remove the role
        vm.startPrank(config.users.admin);
        config.levelContracts.rolesAuthority.removeUserRole(user2.addr, UNPAUSER_ROLE);
        vm.stopPrank();
        assertFalse(config.levelContracts.rolesAuthority.doesUserHaveRole(user2.addr, UNPAUSER_ROLE));
    }

    function test_UnauthorizedAccess() public {
        // Test unauthorized setUserRole
        vm.expectRevert();
        config.levelContracts.rolesAuthority.setUserRole(user1.addr, PAUSER_ROLE, true);

        // Test unauthorized removeUserRole
        vm.expectRevert();
        config.levelContracts.rolesAuthority.removeUserRole(user1.addr, PAUSER_ROLE);

        // Test unauthorized setRoleRemovable
        vm.expectRevert();
        config.levelContracts.rolesAuthority.setRoleRemovable(PAUSER_ROLE, true);
    }

    function test_RoleRemovalEvents() public {
        // Configure role through timelock
        address[] memory targets = new address[](1);
        bytes[] memory payloads = new bytes[](1);

        // Target should be the rolesAuthority, not the timelock
        targets[0] = address(config.levelContracts.rolesAuthority);
        payloads[0] = abi.encodeWithSignature("setRoleRemovable(uint8,bool)", PAUSER_ROLE, true);

        // Schedule and execute the admin action
        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        vm.startPrank(config.users.admin);

        // Test role removal event
        vm.expectEmit(true, true, false, false);
        emit RolesAuthority.UserRoleUpdated(user1.addr, PAUSER_ROLE, false);
        config.levelContracts.rolesAuthority.removeUserRole(user1.addr, PAUSER_ROLE);

        assertFalse(
            config.levelContracts.rolesAuthority.doesUserHaveRole(user1.addr, PAUSER_ROLE),
            "user1 should not have PAUSER_ROLE"
        );

        vm.stopPrank();
    }
}
