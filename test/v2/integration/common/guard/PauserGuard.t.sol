// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Test, Vm} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";
import {PauserGuarded} from "@level/src/v2/common/guard/PauserGuarded.sol";
import {Auth, Authority} from "@solmate/src/auth/Auth.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {ILevelMintingV2Structs} from "@level/src/v2/interfaces/level/ILevelMintingV2.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {MockOracle} from "@level/test/v2/mocks/MockOracle.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";

contract PauserGuardTests is Test, Utils, Configurable {
    using SafeTransferLib for ERC20;

    Vm.Wallet public owner; // Initial deployer
    Vm.Wallet public pauser; // Pauser role
    Vm.Wallet public unpauser; // Unpauser role
    Vm.Wallet public user; // User role, no special permissions

    LevelMintingV2 public levelMinting;
    MockOracle public mockOracle;
    lvlUSD public lvlUsd;

    uint256 public constant INITIAL_BALANCE = 100000000e6;

    function setUp() public {
        forkMainnet(22305203);

        // Create wallets
        owner = vm.createWallet("owner");
        vm.label(owner.addr, "owner");
        pauser = vm.createWallet("pauser");
        vm.label(pauser.addr, "pauser");
        unpauser = vm.createWallet("unpauser");
        vm.label(unpauser.addr, "unpauser");
        user = vm.createWallet("user");
        vm.label(user.addr, "user");

        // Deploy protocol
        DeployLevel deployScript = new DeployLevel();
        vm.prank(owner.addr);
        deployScript.setUp_(1, owner.privateKey);
        config = deployScript.run();

        // Give tokens to user
        deal(address(config.tokens.usdc), user.addr, INITIAL_BALANCE);
        deal(address(config.tokens.usdt), user.addr, INITIAL_BALANCE);

        // Configure mock oracle
        mockOracle = new MockOracle(1e8, 8);

        // Configure roles
        address[] memory targets = new address[](5);
        bytes[] memory payloads = new bytes[](5);

        targets[0] = address(config.levelContracts.rolesAuthority);
        payloads[0] =
            abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(pauser.addr), PAUSER_ROLE, true);

        targets[1] = address(config.levelContracts.rolesAuthority);
        payloads[1] =
            abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(unpauser.addr), UNPAUSER_ROLE, true);

        targets[2] = address(config.levelContracts.levelMintingV2);
        payloads[2] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdc), address(mockOracle), false
        );

        targets[3] = address(config.levelContracts.levelMintingV2);
        payloads[3] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdt), address(mockOracle), false
        );

        targets[4] = address(config.levelContracts.rolesAuthority);
        payloads[4] =
            abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(user.addr), REDEEMER_ROLE, true);

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        levelMinting = LevelMintingV2(address(config.levelContracts.levelMintingV2));
        lvlUsd = lvlUSD(address(config.tokens.lvlUsd));

        vm.startPrank(config.users.admin);
        lvlUsd.setMinter(address(levelMinting));
        vm.stopPrank();
    }

    // ============ Utility Functions ============

    function mint_setup_inffApprovals(
        address caller,
        address beneficiary,
        address collateral,
        uint256 lvlusdAmount,
        uint256 collateralAmount
    ) public returns (ILevelMintingV2Structs.Order memory order) {
        order = ILevelMintingV2Structs.Order({
            beneficiary: beneficiary,
            collateral_asset: collateral,
            lvlusd_amount: lvlusdAmount,
            collateral_amount: collateralAmount
        });

        vm.startPrank(caller);
        ERC20(collateral).safeApprove(address(config.levelContracts.boringVault), type(uint256).max);
        vm.stopPrank();
    }

    // ============ Basic Tests ============

    function test_basicMint() public {
        // Use a larger collateral amount to ensure it meets minimum requirements
        uint256 collateralAmount = 1000e6; // 1000 USDC
        uint256 mintAmount = _adjustAmount(collateralAmount, address(config.tokens.usdc), address(config.tokens.lvlUsd));

        // Check if mint function is paused
        assertFalse(
            config.levelContracts.pauserGuard.isPaused(address(levelMinting), levelMinting.mint.selector),
            "Mint shouldn't be paused"
        );

        // Setup order and approvals
        ILevelMintingV2Structs.Order memory order =
            mint_setup_inffApprovals(user.addr, user.addr, address(config.tokens.usdc), mintAmount, collateralAmount);

        // Execute mint
        vm.prank(user.addr);
        levelMinting.mint(order);

        // Verify results
        assertEq(config.tokens.lvlUsd.balanceOf(user.addr), mintAmount);
        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)), collateralAmount, 1
        );
        vm.stopPrank();
    }

    // ============ Pausing Tests ============

    function test_pauseNonExistingGroup() public {
        vm.prank(pauser.addr);
        vm.expectRevert("Group not found");
        config.levelContracts.pauserGuard.pauseGroup(keccak256("NON_EXISTING_GROUP"));
        vm.stopPrank();
    }

    function test_pauseExistingGroup() public {
        vm.expectEmit(true, true, true, false);
        emit PauserGuard.SelectorPaused(address(levelMinting), levelMinting.completeRedeem.selector, pauser.addr);

        vm.expectEmit(true, true, true, false);
        emit PauserGuard.SelectorPaused(address(levelMinting), levelMinting.initiateRedeem.selector, pauser.addr);

        vm.expectEmit(true, true, false, false);
        emit PauserGuard.GroupPaused(keccak256("REDEEM_PAUSE"), pauser.addr);

        vm.prank(pauser.addr);
        config.levelContracts.pauserGuard.pauseGroup(keccak256("REDEEM_PAUSE"));

        assertTrue(
            config.levelContracts.pauserGuard.isPaused(address(levelMinting), levelMinting.initiateRedeem.selector)
        );
        assertTrue(
            config.levelContracts.pauserGuard.isPaused(address(levelMinting), levelMinting.completeRedeem.selector)
        );
        vm.stopPrank();
    }

    function test_configureGroup_revert_unauthorized() public {
        PauserGuard.FunctionSig[] memory functions = new PauserGuard.FunctionSig[](1);
        functions[0] = PauserGuard.FunctionSig({selector: levelMinting.mint.selector, target: address(levelMinting)});

        vm.prank(user.addr);
        vm.expectRevert();
        config.levelContracts.pauserGuard.configureGroup(keccak256("NEW_GROUP"), functions);
        vm.stopPrank();
    }

    function test_pauseSelector() public {
        vm.prank(pauser.addr);
        config.levelContracts.pauserGuard.pauseSelector(address(levelMinting), levelMinting.mint.selector);

        assertTrue(config.levelContracts.pauserGuard.isPaused(address(levelMinting), levelMinting.mint.selector));
        vm.stopPrank();
    }

    function test_mintBeforeAndAfterPause() public {
        vm.prank(pauser.addr);
        config.levelContracts.pauserGuard.pauseSelector(address(levelMinting), levelMinting.mint.selector);
        vm.stopPrank();

        uint256 collateralAmount = 1000e6; // 1000 USDC
        uint256 mintAmount = _adjustAmount(collateralAmount, address(config.tokens.usdc), address(config.tokens.lvlUsd));

        // Setup order and approvals
        ILevelMintingV2Structs.Order memory order =
            mint_setup_inffApprovals(user.addr, user.addr, address(config.tokens.usdc), mintAmount, collateralAmount);

        // Try minting when paused
        vm.prank(user.addr);
        vm.expectRevert(PauserGuarded.Paused.selector);
        levelMinting.mint(order);

        // Unpause the selector
        vm.prank(unpauser.addr);
        config.levelContracts.pauserGuard.unpauseSelector(address(levelMinting), levelMinting.mint.selector);
        vm.stopPrank();

        assertFalse(config.levelContracts.pauserGuard.isPaused(address(levelMinting), levelMinting.mint.selector));

        // Mint again
        vm.prank(user.addr);
        levelMinting.mint(order);
        vm.stopPrank();

        assertEq(config.tokens.lvlUsd.balanceOf(user.addr), mintAmount);
        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)), collateralAmount, 1
        );
    }

    function test_pauseSelector_revert_notPausable() public {
        vm.prank(pauser.addr);
        vm.expectRevert("Selector not pausable");
        config.levelContracts.pauserGuard.pauseSelector(
            address(levelMinting), bytes4(keccak256("nonExistentFunction()"))
        );
    }

    function test_groupPause() public {
        uint256 collateralAmount = 1000e6; // 1000 USDC
        uint256 mintAmount = _adjustAmount(collateralAmount, address(config.tokens.usdc), address(config.tokens.lvlUsd));

        // Setup order and approvals
        ILevelMintingV2Structs.Order memory order =
            mint_setup_inffApprovals(user.addr, user.addr, address(config.tokens.usdc), mintAmount, collateralAmount);

        // Execute mint
        vm.startPrank(user.addr);
        levelMinting.mint(order);

        assertEq(config.tokens.lvlUsd.balanceOf(user.addr), mintAmount);
        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)), collateralAmount, 1
        );

        // Approve lvlUsd
        config.tokens.lvlUsd.approve(address(levelMinting), type(uint256).max);

        uint256 toRedeem = 1000e18; // 1000 lvlUsd
        uint256 minCollateralAmount =
            _adjustAmount(toRedeem, address(config.tokens.lvlUsd), address(config.tokens.usdc)) - 1;
        vm.stopPrank();

        // =============== Pause Redeem Group ===============
        vm.prank(pauser.addr);
        config.levelContracts.pauserGuard.pauseGroup(keccak256("REDEEM_PAUSE"));
        // ==================================================

        vm.startPrank(user.addr);
        // Execute redeem
        vm.expectRevert(PauserGuarded.Paused.selector);
        levelMinting.initiateRedeem(address(config.tokens.usdc), toRedeem, minCollateralAmount);
        vm.stopPrank();

        // Unpause only initiateRedeem
        vm.prank(unpauser.addr);
        config.levelContracts.pauserGuard.unpauseSelector(address(levelMinting), levelMinting.initiateRedeem.selector);

        // Execute redeem
        vm.startPrank(user.addr);
        (, uint256 collateralAmountOnInitiate) =
            levelMinting.initiateRedeem(address(config.tokens.usdc), toRedeem, minCollateralAmount);

        assertEq(
            config.tokens.usdc.balanceOf(address(levelMinting.silo())),
            collateralAmountOnInitiate,
            "Silo USDC balance is wrong"
        );
        assertEq(
            levelMinting.pendingRedemption(user.addr, address(config.tokens.usdc)),
            collateralAmountOnInitiate,
            "Pending redemption is wrong"
        );

        vm.warp(block.timestamp + 5 minutes);
        vm.expectRevert(PauserGuarded.Paused.selector);
        levelMinting.completeRedeem(address(config.tokens.usdc), user.addr);
        vm.stopPrank();

        // Unpause completeRedeem
        vm.prank(unpauser.addr);
        config.levelContracts.pauserGuard.unpauseSelector(address(levelMinting), levelMinting.completeRedeem.selector);

        // Execute redeem
        vm.startPrank(user.addr);
        uint256 collateralAmountOnComplete = levelMinting.completeRedeem(address(config.tokens.usdc), user.addr);

        assertEq(collateralAmountOnInitiate, collateralAmountOnComplete, "Collateral amount is wrong");
        assertEq(config.tokens.lvlUsd.balanceOf(user.addr), 0, "User lvlUSD balance is wrong");
        assertEq(config.tokens.usdc.balanceOf(user.addr), INITIAL_BALANCE, "User USDC balance is wrong");
        vm.stopPrank();
    }
}
