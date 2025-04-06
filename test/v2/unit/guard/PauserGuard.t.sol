// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";
import {PauserGuarded} from "@level/src/v2/common/guard/PauserGuarded.sol";
import {Authority} from "@solmate/src/auth/Auth.sol";
import {RolesAuthority} from "@solmate/src/auth/authorities/RolesAuthority.sol";

contract MockTarget is PauserGuarded {
    function initialize(address _guard) external initializer {
        __PauserGuarded_init(_guard);
    }

    function mint() external notPaused returns (bool) {
        return true;
    }

    function mintBatch() external notPaused returns (bool) {
        return true;
    }

    function redeem() external notPaused returns (bool) {
        return true;
    }

    function redeemBatch() external notPaused returns (bool) {
        return true;
    }
}

contract PauserGuardTest is Test {
    // Contract instances
    PauserGuard public pauserGuard;
    MockTarget public mockTarget;
    RolesAuthority public rolesAuthority;

    // Roles
    address public owner; // Deploys and owns the PauserGuard (e.g. timelock)
    address public pauser; // Has role to pause/unpause functions
    address public unpauser; // Has role to unpause functions
    address public user; // Has no special permissions
    uint8 PAUSER_ROLE = 1;
    uint8 UNPAUSER_ROLE = 2;

    // Test constants
    bytes32 public constant MINT_GROUP = keccak256("MINT_GROUP");
    bytes32 public constant REDEEM_GROUP = keccak256("REDEEM_GROUP");
    bytes32 public constant EMERGENCY_GROUP = keccak256("EMERGENCY_GROUP");

    function setUp() public {
        // Setup roles
        owner = makeAddr("owner");
        pauser = makeAddr("pauser");
        unpauser = makeAddr("unpauser");
        user = makeAddr("user");

        // Setup roles authority
        vm.startPrank(owner);
        rolesAuthority = new RolesAuthority(owner, Authority(address(0)));

        // Deploy PauserGuard
        pauserGuard = new PauserGuard(owner, rolesAuthority);

        // Set role capability for pauser
        rolesAuthority.setRoleCapability(
            PAUSER_ROLE, address(pauserGuard), bytes4(abi.encodeWithSignature("pauseGroup(bytes32)")), true
        );
        rolesAuthority.setRoleCapability(
            UNPAUSER_ROLE, address(pauserGuard), bytes4(abi.encodeWithSignature("unpauseGroup(bytes32)")), true
        );
        rolesAuthority.setRoleCapability(
            PAUSER_ROLE, address(pauserGuard), bytes4(abi.encodeWithSignature("pauseSelector(address,bytes4)")), true
        );
        rolesAuthority.setRoleCapability(
            UNPAUSER_ROLE,
            address(pauserGuard),
            bytes4(abi.encodeWithSignature("unpauseSelector(address,bytes4)")),
            true
        );
        rolesAuthority.setUserRole(pauser, PAUSER_ROLE, true);
        rolesAuthority.setUserRole(unpauser, UNPAUSER_ROLE, true);

        // Deploy contracts
        mockTarget = new MockTarget();
        mockTarget.initialize(address(pauserGuard));
        vm.stopPrank();
    }

    // ============ Helper Functions ============

    function _configureMintGroup() internal {
        vm.startPrank(owner);
        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](2);
        signatures[0] = PauserGuard.FunctionSig({selector: MockTarget.mint.selector, target: address(mockTarget)});
        signatures[1] = PauserGuard.FunctionSig({selector: MockTarget.mintBatch.selector, target: address(mockTarget)});
        pauserGuard.configureGroup(MINT_GROUP, signatures);

        vm.stopPrank();
    }

    function _configureRedeemGroup() internal {
        vm.startPrank(owner);
        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](2);
        signatures[0] = PauserGuard.FunctionSig({selector: MockTarget.redeem.selector, target: address(mockTarget)});
        signatures[1] =
            PauserGuard.FunctionSig({selector: MockTarget.redeemBatch.selector, target: address(mockTarget)});
        pauserGuard.configureGroup(REDEEM_GROUP, signatures);
        vm.stopPrank();
    }

    function _configureEmergencyGroup() internal {
        vm.startPrank(owner);
        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](4);
        signatures[0] = PauserGuard.FunctionSig({selector: MockTarget.mint.selector, target: address(mockTarget)});
        signatures[1] = PauserGuard.FunctionSig({selector: MockTarget.mintBatch.selector, target: address(mockTarget)});
        signatures[2] = PauserGuard.FunctionSig({selector: MockTarget.redeem.selector, target: address(mockTarget)});
        signatures[3] =
            PauserGuard.FunctionSig({selector: MockTarget.redeemBatch.selector, target: address(mockTarget)});

        pauserGuard.configureGroup(EMERGENCY_GROUP, signatures);
        vm.stopPrank();
    }

    // ============ Configuration Tests ============

    /*
    Owner should be able to configure group
    */
    function test_ConfigureGroup_Success() public {
        vm.startPrank(owner);

        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](2);
        signatures[0] = PauserGuard.FunctionSig({selector: MockTarget.mint.selector, target: address(mockTarget)});
        signatures[1] = PauserGuard.FunctionSig({selector: MockTarget.mintBatch.selector, target: address(mockTarget)});

        vm.expectEmit(true, true, true, false);
        emit PauserGuard.FunctionSigConfigured(MINT_GROUP, address(mockTarget), MockTarget.mint.selector);

        vm.expectEmit(true, true, true, false);
        emit PauserGuard.FunctionSigConfigured(MINT_GROUP, address(mockTarget), MockTarget.mintBatch.selector);

        pauserGuard.configureGroup(MINT_GROUP, signatures);

        assertTrue(pauserGuard.isPausableSelector(address(mockTarget), MockTarget.mint.selector));
        assertTrue(pauserGuard.isPausableSelector(address(mockTarget), MockTarget.mintBatch.selector));
    }

    /*
    Owner should not be able to configure group with empty signatures
    */
    function test_ConfigureGroup_EmptySignatures() public {
        vm.startPrank(owner);
        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](0);

        vm.expectRevert("Selectors must not be empty");
        pauserGuard.configureGroup(MINT_GROUP, signatures);
    }

    /*
    Owner should not be able to configure group with too many signatures
    */
    function test_ConfigureGroup_TooManySignatures() public {
        vm.startPrank(owner);
        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](256);

        vm.expectRevert("Selectors must not exceed 255");
        pauserGuard.configureGroup(MINT_GROUP, signatures);
        vm.stopPrank();
    }

    /*
    User should not be able to configure group
    */
    function test_ConfigureGroup_User() public {
        vm.startPrank(user);
        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](1);
        signatures[0] = PauserGuard.FunctionSig({selector: MockTarget.mint.selector, target: address(mockTarget)});

        vm.expectRevert("UNAUTHORIZED");
        pauserGuard.configureGroup(MINT_GROUP, signatures);
        vm.stopPrank();
    }

    /*
    Pauser should not be able to configure group
    */
    function test_ConfigureGroup_Pauser() public {
        vm.startPrank(pauser);
        PauserGuard.FunctionSig[] memory signatures = new PauserGuard.FunctionSig[](1);
        signatures[0] = PauserGuard.FunctionSig({selector: MockTarget.mint.selector, target: address(mockTarget)});

        vm.expectRevert("UNAUTHORIZED");
        pauserGuard.configureGroup(MINT_GROUP, signatures);
        vm.stopPrank();
    }

    /*
    Pausing one group should not affect other groups
    */
    function test_PauseGroup_OneGroup() public {
        _configureMintGroup();

        assertTrue(
            pauserGuard.isPausableSelector(address(mockTarget), MockTarget.mint.selector),
            "mint selector should be pausable"
        );
        assertTrue(
            pauserGuard.isPausableSelector(address(mockTarget), MockTarget.mintBatch.selector),
            "mintBatch selector should be pausable"
        );
        assertFalse(
            pauserGuard.isPausableSelector(address(mockTarget), MockTarget.redeem.selector),
            "redeem selector should not be pausable"
        );
        assertFalse(
            pauserGuard.isPausableSelector(address(mockTarget), MockTarget.redeemBatch.selector),
            "redeemBatch selector should not be pausable"
        );
    }

    // ============ Pausing Tests ============

    function test_PauseSelector_Success() public {
        _configureMintGroup();

        vm.startPrank(pauser);
        vm.expectEmit(true, true, true, true);
        emit PauserGuard.SelectorPaused(address(mockTarget), MockTarget.mint.selector, pauser);

        pauserGuard.pauseSelector(address(mockTarget), MockTarget.mint.selector);

        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));
    }

    /*
    Pauser should not be able to pause selector that is not pausable
    */
    function test_PauseSelector_NotPausable() public {
        vm.startPrank(pauser);
        vm.expectRevert("Selector not pausable");
        pauserGuard.pauseSelector(address(mockTarget), MockTarget.redeem.selector);
    }

    /*
    Unpauser should be able to unpause selector
    */
    function test_UnpauseSelector_Success() public {
        _configureMintGroup();

        // First pause the selector
        vm.startPrank(pauser);
        pauserGuard.pauseSelector(address(mockTarget), MockTarget.mint.selector);
        vm.stopPrank();

        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));

        // Then unpause it
        vm.expectEmit(true, true, true, false);
        emit PauserGuard.SelectorUnpaused(address(mockTarget), MockTarget.mint.selector, unpauser);

        vm.startPrank(unpauser);
        pauserGuard.unpauseSelector(address(mockTarget), MockTarget.mint.selector);
        vm.stopPrank();

        assertFalse(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));
    }

    /*
    Unpauser should not be able to unpause selector that is not paused
    */
    function test_UnpauseSelector_NotPaused() public {
        _configureMintGroup();

        vm.startPrank(unpauser);
        vm.expectRevert("Selector not paused");
        pauserGuard.unpauseSelector(address(mockTarget), MockTarget.redeem.selector);
        vm.stopPrank();
    }

    /*
    User should not be able to pause selector
    */
    function test_PauseSelector_User() public {
        vm.startPrank(user);
        vm.expectRevert("UNAUTHORIZED");
        pauserGuard.pauseSelector(address(mockTarget), MockTarget.mint.selector);
        vm.stopPrank();
    }

    /*
    User should not be able to unpause selector
    */
    function test_UnpauseSelector_User() public {
        vm.startPrank(user);
        vm.expectRevert("UNAUTHORIZED");
        pauserGuard.unpauseSelector(address(mockTarget), MockTarget.mint.selector);
    }

    /*
    Pauser should not be able to unpause selector
    */
    function test_UnpauseSelector_Pauser() public {
        _configureMintGroup();

        vm.startPrank(pauser);
        pauserGuard.pauseSelector(address(mockTarget), MockTarget.mint.selector);

        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));

        vm.expectRevert("UNAUTHORIZED");
        pauserGuard.unpauseSelector(address(mockTarget), MockTarget.mint.selector);
        vm.stopPrank();
    }

    /*
    Unpauser should not be able to pause selector
    */
    function test_PauseSelector_Unpauser() public {
        _configureMintGroup();

        vm.startPrank(unpauser);
        vm.expectRevert("UNAUTHORIZED");
        pauserGuard.pauseSelector(address(mockTarget), MockTarget.mint.selector);
        vm.stopPrank();
    }

    // ============ Group Pausing Tests ============

    /*
    Trying to pause/unpause a non-existent group should revert
    */
    function test_PauseUnpauseGroup_NonExistent() public {
        vm.startPrank(pauser);
        vm.expectRevert("Group not found");
        pauserGuard.pauseGroup(MINT_GROUP);
        vm.stopPrank();

        vm.startPrank(unpauser);
        vm.expectRevert("Group not found");
        pauserGuard.unpauseGroup(MINT_GROUP);
        vm.stopPrank();
    }

    /*
    PAUSER_ROLE should have access to pauseGroup
    */
    function test_PauseGroup_PauserRole() public {
        assertTrue(
            rolesAuthority.doesRoleHaveCapability(
                PAUSER_ROLE, address(pauserGuard), bytes4(abi.encodeWithSignature("pauseGroup(bytes32)"))
            ),
            "pauser role should have access to pauseGroup"
        );
        assertTrue(rolesAuthority.doesUserHaveRole(pauser, PAUSER_ROLE), "pauser should have pauser role");
    }

    /*
    Pauser should be able to pause group
    */
    function test_PauseGroup_Success() public {
        _configureMintGroup();

        vm.startPrank(pauser);
        vm.expectEmit(true, true, true, false);
        emit PauserGuard.SelectorPaused(address(mockTarget), MockTarget.mint.selector, pauser);

        vm.expectEmit(true, true, true, false);
        emit PauserGuard.SelectorPaused(address(mockTarget), MockTarget.mintBatch.selector, pauser);

        vm.expectEmit(true, true, true, false);
        emit PauserGuard.GroupPaused(MINT_GROUP, pauser);

        pauserGuard.pauseGroup(MINT_GROUP);

        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));
        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mintBatch.selector));
        vm.stopPrank();
    }

    /*
    Unpauser should be able to unpause group
    */
    function test_UnpauseGroup_Success() public {
        _configureMintGroup();

        // First pause the group
        vm.startPrank(pauser);
        pauserGuard.pauseGroup(MINT_GROUP);
        vm.stopPrank();

        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));
        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mintBatch.selector));

        vm.startPrank(unpauser);

        // Then unpause it
        vm.expectEmit(true, true, true, false);
        emit PauserGuard.SelectorUnpaused(address(mockTarget), MockTarget.mint.selector, unpauser);

        vm.expectEmit(true, true, true, false);
        emit PauserGuard.SelectorUnpaused(address(mockTarget), MockTarget.mintBatch.selector, unpauser);

        vm.expectEmit(true, true, true, false);
        emit PauserGuard.GroupUnpaused(MINT_GROUP, unpauser);

        pauserGuard.unpauseGroup(MINT_GROUP);

        assertFalse(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));
        assertFalse(pauserGuard.isPaused(address(mockTarget), MockTarget.mintBatch.selector));
        vm.stopPrank();
    }

    // ============ Calling Paused Functions ============

    /*
    User should not be able to call paused function
    */
    function test_CallPausedFunction_User() public {
        _configureMintGroup();

        vm.startPrank(pauser);
        pauserGuard.pauseGroup(MINT_GROUP);
        vm.stopPrank();

        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector), "mint should be paused");
        assertTrue(
            pauserGuard.isPaused(address(mockTarget), MockTarget.mintBatch.selector), "mintBatch should be paused"
        );

        vm.startPrank(user);
        vm.expectRevert(PauserGuarded.Paused.selector);
        mockTarget.mint();
        vm.expectRevert(PauserGuarded.Paused.selector);
        mockTarget.mintBatch();
        vm.stopPrank();
    }

    /*
    Function should be able to be unpaused after a group pause
    */
    function test_FunctionFromGroup_Unpause() public {
        _configureMintGroup();

        vm.startPrank(pauser);
        pauserGuard.pauseGroup(MINT_GROUP);
        vm.stopPrank();

        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));
        assertTrue(pauserGuard.isPaused(address(mockTarget), MockTarget.mintBatch.selector));

        vm.startPrank(unpauser);
        pauserGuard.unpauseSelector(address(mockTarget), MockTarget.mint.selector);
        vm.stopPrank();

        assertFalse(pauserGuard.isPaused(address(mockTarget), MockTarget.mint.selector));

        vm.startPrank(user);
        assertTrue(mockTarget.mint());
        vm.expectRevert(PauserGuarded.Paused.selector);
        mockTarget.mintBatch();
        vm.stopPrank();
    }

    // ============ View Function Tests ============

    function test_GetGroupFunctions() public {
        _configureMintGroup();

        PauserGuard.FunctionSig[] memory retrievedSignatures = pauserGuard.getGroupFunctions(MINT_GROUP);

        assertEq(retrievedSignatures.length, 2);
        assertEq(retrievedSignatures[0].selector, MockTarget.mint.selector);
        assertEq(retrievedSignatures[0].target, address(mockTarget));
        assertEq(retrievedSignatures[1].selector, MockTarget.mintBatch.selector);
        assertEq(retrievedSignatures[1].target, address(mockTarget));
    }

    function test_GetGroupFunctions_EmptyGroup() public view {
        PauserGuard.FunctionSig[] memory retrievedSignatures = pauserGuard.getGroupFunctions(MINT_GROUP);
        assertEq(retrievedSignatures.length, 0);
    }
}
