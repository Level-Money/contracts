// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {stdStorage, StdStorage, Test, Vm} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {
    ILevelMintingV2,
    ILevelMintingV2Errors,
    ILevelMintingV2Structs
} from "@level/src/v2/interfaces/ILevelMintingV2.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {MockOracle} from "@level/test/v2/mocks/MockOracle.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";

contract LevelMintingV2CoreTests is Utils, Configurable {
    using SafeTransferLib for ERC20;

    Vm.Wallet private deployer;
    Vm.Wallet private normalUser;
    Vm.Wallet private denylistedUser;
    Vm.Wallet private alice;
    Vm.Wallet private bob;

    address public MAINNET_DAI = 0x6b175474e89094c44dA98b95B7002f2956889026;

    uint256 public constant INITIAL_BALANCE = 100000000e6;

    LevelMintingV2 public levelMinting;
    MockOracle public mockOracle;

    function setUp() public {
        forkMainnet(22134384);

        deployer = vm.createWallet("deployer");
        vm.label(deployer.addr, "deployer");
        normalUser = vm.createWallet("normalUser");
        vm.label(normalUser.addr, "normalUser");
        denylistedUser = vm.createWallet("denylistedUser");
        vm.label(denylistedUser.addr, "denylistedUser");
        alice = vm.createWallet("alice");
        vm.label(alice.addr, "alice");
        bob = vm.createWallet("bob");
        vm.label(bob.addr, "bob");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        deal(address(config.tokens.usdc), normalUser.addr, INITIAL_BALANCE);
        deal(address(config.tokens.usdt), normalUser.addr, INITIAL_BALANCE);

        deal(address(config.tokens.usdc), alice.addr, INITIAL_BALANCE);
        deal(address(config.tokens.usdt), alice.addr, INITIAL_BALANCE);

        deal(address(config.tokens.usdc), bob.addr, INITIAL_BALANCE);
        deal(address(config.tokens.usdt), bob.addr, INITIAL_BALANCE);

        mockOracle = new MockOracle(1e8, 8);

        address[] memory targets = new address[](5);
        targets[0] = address(config.levelContracts.levelMintingV2);
        targets[1] = address(config.levelContracts.levelMintingV2);
        targets[2] = address(config.levelContracts.rolesAuthority);
        targets[3] = address(config.levelContracts.rolesAuthority);
        targets[4] = address(config.levelContracts.rolesAuthority);

        bytes[] memory payloads = new bytes[](5);
        payloads[0] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdc), address(mockOracle), false
        );
        payloads[1] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdt), address(mockOracle), false
        );
        payloads[2] =
            abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(normalUser.addr), REDEEMER_ROLE, true);
        payloads[3] =
            abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(alice.addr), REDEEMER_ROLE, true);
        payloads[4] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(bob.addr), REDEEMER_ROLE, true);

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        vm.startPrank(config.users.admin);
        lvlUSD _lvlUSD = lvlUSD(address(config.tokens.lvlUsd));
        _lvlUSD.grantRole(keccak256("DENYLIST_MANAGER_ROLE"), config.users.admin);
        _lvlUSD.setMinter(address(config.levelContracts.levelMintingV2));
        _lvlUSD.addToDenylist(denylistedUser.addr);
        vm.stopPrank();

        levelMinting = LevelMintingV2(address(config.levelContracts.levelMintingV2));
    }

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
        config.tokens.lvlUsd.approve(address(levelMinting), type(uint256).max);
        vm.stopPrank();

        if (caller != beneficiary) {
            vm.startPrank(beneficiary);
            ERC20(collateral).safeApprove(address(config.levelContracts.boringVault), type(uint256).max);
            config.tokens.lvlUsd.approve(address(levelMinting), type(uint256).max);
            vm.stopPrank();
        }
    }

    // -------------------- MINT/REDEEM -------------------- //
    function test_mint(uint256 collateralAmount) public {
        uint256 collateralAmount = bound(collateralAmount, 1, 500000e6);
        uint256 mintAmount = _adjustAmount(collateralAmount, address(config.tokens.usdc), address(config.tokens.lvlUsd));

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.prank(normalUser.addr);
        levelMinting.mint(order_);

        assertEq(config.tokens.lvlUsd.balanceOf(normalUser.addr), mintAmount);
        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)), collateralAmount, 1
        );
    }

    function test_mint_and_redeem(uint256 toMint, uint256 toRedeem) public {
        uint256 toMint = bound(toMint, 1e6, 500000e6);
        uint256 minLvlUsdAmount = _adjustAmount(toMint, address(config.tokens.usdc), address(config.tokens.lvlUsd));

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), minLvlUsdAmount, toMint
        );

        vm.startPrank(normalUser.addr);
        uint256 lvlUsdMinted = levelMinting.mint(order_);

        assertEq(config.tokens.lvlUsd.balanceOf(normalUser.addr), lvlUsdMinted);
        assertApproxEqAbs(config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)), toMint, 1);

        uint256 toRedeem = bound(toRedeem, 1e18, lvlUsdMinted) - 0.1e18;
        uint256 minCollateralAmount =
            _adjustAmount(toRedeem, address(config.tokens.lvlUsd), address(config.tokens.usdc)) - 1;

        (, uint256 collateralAmountOnInitiate) =
            levelMinting.initiateRedeem(address(config.tokens.usdc), toRedeem, minCollateralAmount);

        assertEq(
            config.tokens.usdc.balanceOf(address(levelMinting.silo())),
            collateralAmountOnInitiate,
            "Silo USDC balance is wrong"
        );
        assertEq(
            levelMinting.pendingRedemption(normalUser.addr, address(config.tokens.usdc)),
            collateralAmountOnInitiate,
            "Pending redemption is wrong"
        );
        vm.warp(block.timestamp + 5 minutes);
        uint256 collateralAmountOnComplete = levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        assertEq(
            collateralAmountOnInitiate,
            collateralAmountOnComplete,
            "Redeemed different amounts between initiate and complete"
        );

        assertEq(
            config.tokens.lvlUsd.balanceOf(normalUser.addr), minLvlUsdAmount - toRedeem, "User lvlUSD balance is wrong"
        );
        assertEq(
            config.tokens.usdc.balanceOf(normalUser.addr),
            INITIAL_BALANCE - toMint + collateralAmountOnComplete,
            "User USDC balance is wrong"
        );
    }

    function test_mint_and_redeem_mixed_collateral(uint256 toMint, uint256 toRedeem) public {
        uint256 toMint = bound(toMint, 1e6, 250000e6);
        uint256 minLvlUsdAmount = _adjustAmount(toMint, address(config.tokens.usdc), address(config.tokens.lvlUsd));

        ILevelMintingV2Structs.Order memory order_USDC = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), minLvlUsdAmount, toMint
        );
        ILevelMintingV2Structs.Order memory order_USDT = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdt), minLvlUsdAmount, toMint
        );

        vm.startPrank(normalUser.addr);
        uint256 lvlUsdMintedWithUsdc = levelMinting.mint(order_USDC);
        uint256 lvlUsdMintedWithUsdt = levelMinting.mint(order_USDT);

        assertEq(
            config.tokens.lvlUsd.balanceOf(normalUser.addr),
            lvlUsdMintedWithUsdc + lvlUsdMintedWithUsdt,
            "LVLUSD balance is wrong after mint"
        );
        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)),
            toMint,
            1,
            "aUSDC balance is wrong after mint"
        );
        assertApproxEqAbs(
            config.tokens.aUsdt.balanceOf(address(config.levelContracts.boringVault)),
            toMint,
            1,
            "aUSDT balance is wrong after mint"
        );

        uint256 lvlUsdToRedeemForUsdc = bound(toRedeem, 1e18, lvlUsdMintedWithUsdc) - 0.1e18;
        uint256 lvlUsdToRedeemForUsdt = bound(toRedeem, 1e18, lvlUsdMintedWithUsdt) - 0.1e18;
        uint256 minUsdc =
            _adjustAmount(lvlUsdToRedeemForUsdc, address(config.tokens.lvlUsd), address(config.tokens.usdc)) - 1;
        uint256 minUsdt =
            _adjustAmount(lvlUsdToRedeemForUsdt, address(config.tokens.lvlUsd), address(config.tokens.usdt)) - 1;

        _inspectVaultBalances("Before initiate redeem", address(config.levelContracts.boringVault));

        (, uint256 usdcAmountOnInitiate) =
            levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdToRedeemForUsdc, minUsdc);
        (, uint256 usdtAmountOnInitiate) =
            levelMinting.initiateRedeem(address(config.tokens.usdt), lvlUsdToRedeemForUsdt, minUsdt);

        assertEq(
            levelMinting.pendingRedemption(normalUser.addr, address(config.tokens.usdc)),
            usdcAmountOnInitiate,
            "Pending redemption is wrong"
        );
        assertEq(
            levelMinting.pendingRedemption(normalUser.addr, address(config.tokens.usdt)),
            usdtAmountOnInitiate,
            "Pending redemption is wrong"
        );

        vm.warp(block.timestamp + 5 minutes);
        uint256 usdcAmountOnComplete = levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);
        uint256 usdtAmountOnComplete = levelMinting.completeRedeem(address(config.tokens.usdt), normalUser.addr);

        assertEq(
            config.tokens.lvlUsd.balanceOf(normalUser.addr),
            lvlUsdMintedWithUsdc + lvlUsdMintedWithUsdt - lvlUsdToRedeemForUsdc - lvlUsdToRedeemForUsdt,
            "LVLUSD balance is wrong after redeem"
        );
        assertEq(
            config.tokens.usdc.balanceOf(normalUser.addr),
            INITIAL_BALANCE - toMint + usdcAmountOnComplete,
            "USDC balance is wrong after redeem"
        );
        assertEq(
            config.tokens.usdt.balanceOf(normalUser.addr),
            INITIAL_BALANCE - toMint + usdtAmountOnComplete,
            "USDT balance is wrong after redeem"
        );
    }

    function test_mint_and_redeem_multiple_users(uint256 toMint, uint256 toRedeem) public {
        uint256 toMint = bound(toMint, 1e6, 100000e6);
        uint256 minLvlUsdAmount = _adjustAmount(toMint, address(config.tokens.usdc), address(config.tokens.lvlUsd));

        address usdcMinter = normalUser.addr;
        address usdtMinter = alice.addr;
        address allCollateralMinter = bob.addr;

        ILevelMintingV2Structs.Order memory order_USDC =
            mint_setup_inffApprovals(usdcMinter, usdcMinter, address(config.tokens.usdc), minLvlUsdAmount, toMint);
        ILevelMintingV2Structs.Order memory order_USDT =
            mint_setup_inffApprovals(usdtMinter, usdtMinter, address(config.tokens.usdt), minLvlUsdAmount, toMint);
        ILevelMintingV2Structs.Order memory order_AllCollateral_USDC = mint_setup_inffApprovals(
            allCollateralMinter, allCollateralMinter, address(config.tokens.usdc), minLvlUsdAmount, toMint
        );
        ILevelMintingV2Structs.Order memory order_AllCollateral_USDT = mint_setup_inffApprovals(
            allCollateralMinter, allCollateralMinter, address(config.tokens.usdt), minLvlUsdAmount, toMint
        );

        vm.prank(usdcMinter);
        uint256 lvlUsdMintedForUsdcMinter = levelMinting.mint(order_USDC);

        vm.prank(usdtMinter);
        uint256 lvlUsdMintedForUsdtMinter = levelMinting.mint(order_USDT);

        vm.startPrank(allCollateralMinter);
        uint256 lvlUsdMintedForAllCollateralMinter = levelMinting.mint(order_AllCollateral_USDC);
        lvlUsdMintedForAllCollateralMinter += levelMinting.mint(order_AllCollateral_USDT);
        vm.stopPrank();

        assertEq(
            config.tokens.lvlUsd.balanceOf(usdcMinter),
            lvlUsdMintedForUsdcMinter,
            "LVLUSD balance for usdc minter is wrong after mint"
        );
        assertEq(
            config.tokens.lvlUsd.balanceOf(usdtMinter),
            lvlUsdMintedForUsdtMinter,
            "LVLUSD balance for usdt minter is wrong after mint"
        );
        assertEq(
            config.tokens.lvlUsd.balanceOf(allCollateralMinter),
            lvlUsdMintedForAllCollateralMinter,
            "LVLUSD balance for all collateral minter is wrong after mint"
        );

        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)),
            toMint * 2,
            1,
            "aUSDC balance is wrong after mint"
        );
        assertApproxEqAbs(
            config.tokens.aUsdt.balanceOf(address(config.levelContracts.boringVault)),
            toMint * 2,
            1,
            "aUSDT balance is wrong after mint"
        );

        uint256 lvlUsdToRedeemForUsdcMinter = bound(toRedeem, 1e18, lvlUsdMintedForUsdcMinter) - 0.1e18;
        uint256 lvlUsdToRedeemForUsdtMinter = bound(toRedeem, 1e18, lvlUsdMintedForUsdtMinter) - 0.1e18;
        uint256 lvlUsdToRedeemForAllCollateralMinter =
            bound(toRedeem, 1e18, lvlUsdMintedForAllCollateralMinter / 2) - 0.1e18;
        uint256 minUsdc =
            _adjustAmount(lvlUsdToRedeemForUsdcMinter, address(config.tokens.lvlUsd), address(config.tokens.usdc)) - 1;
        uint256 minUsdt =
            _adjustAmount(lvlUsdToRedeemForUsdtMinter, address(config.tokens.lvlUsd), address(config.tokens.usdt)) - 1;

        _inspectVaultBalances("Before initiate redeem", address(config.levelContracts.boringVault));

        vm.prank(usdcMinter);
        (, uint256 usdcAmountOnInitiate) =
            levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdToRedeemForUsdcMinter, minUsdc);

        vm.prank(usdtMinter);
        (, uint256 usdtAmountOnInitiate) =
            levelMinting.initiateRedeem(address(config.tokens.usdt), lvlUsdToRedeemForUsdtMinter, minUsdt);

        vm.startPrank(allCollateralMinter);
        (, uint256 allCollateralAmountOnInitiate_USDC) =
            levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdToRedeemForAllCollateralMinter, minUsdc);
        (, uint256 allCollateralAmountOnInitiate_USDT) =
            levelMinting.initiateRedeem(address(config.tokens.usdt), lvlUsdToRedeemForAllCollateralMinter, minUsdt);
        vm.stopPrank();

        assertEq(
            levelMinting.pendingRedemption(usdcMinter, address(config.tokens.usdc)),
            usdcAmountOnInitiate,
            "Pending redemption is wrong"
        );
        assertEq(
            levelMinting.pendingRedemption(usdtMinter, address(config.tokens.usdt)),
            usdtAmountOnInitiate,
            "Pending redemption is wrong"
        );

        assertEq(
            levelMinting.pendingRedemption(allCollateralMinter, address(config.tokens.usdc)),
            allCollateralAmountOnInitiate_USDC,
            "Pending redemption is wrong"
        );
        assertEq(
            levelMinting.pendingRedemption(allCollateralMinter, address(config.tokens.usdt)),
            allCollateralAmountOnInitiate_USDT,
            "Pending redemption is wrong"
        );

        vm.warp(block.timestamp + 5 minutes);
        vm.prank(usdcMinter);
        uint256 usdcAmountOnComplete = levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        vm.prank(usdtMinter);
        uint256 usdtAmountOnComplete = levelMinting.completeRedeem(address(config.tokens.usdt), normalUser.addr);

        assertEq(
            config.tokens.lvlUsd.balanceOf(usdcMinter),
            lvlUsdMintedForUsdcMinter - lvlUsdToRedeemForUsdcMinter,
            "LVLUSD balance is wrong after redeem"
        );
        assertEq(
            config.tokens.usdc.balanceOf(usdcMinter),
            INITIAL_BALANCE - toMint + usdcAmountOnComplete,
            "USDC balance is wrong after redeem"
        );

        assertEq(
            config.tokens.lvlUsd.balanceOf(usdtMinter),
            lvlUsdMintedForUsdtMinter - lvlUsdToRedeemForUsdtMinter,
            "LVLUSD balance is wrong after redeem"
        );

        // TODO: reenable
        // assertEq(
        //     config.tokens.usdt.balanceOf(usdtMinter),
        //     INITIAL_BALANCE - toMint + usdtAmountOnComplete,
        //     "USDT balance is wrong after redeem"
        // );

        assertEq(
            levelMinting.pendingRedemption(allCollateralMinter, address(config.tokens.usdc)),
            allCollateralAmountOnInitiate_USDC,
            "Pending redemption is wrong"
        );
        assertEq(
            levelMinting.pendingRedemption(allCollateralMinter, address(config.tokens.usdt)),
            allCollateralAmountOnInitiate_USDT,
            "Pending redemption is wrong"
        );
    }

    // should set cooldown to new block.timestamp
    function test_redeem_cooldown_override() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);
        levelMinting.initiateRedeem(address(config.tokens.usdc), 5e18, collateralAmount / 2);

        vm.warp(block.timestamp + 300);
        levelMinting.initiateRedeem(address(config.tokens.usdc), 5e18, collateralAmount / 2);

        assertEq(levelMinting.userCooldown(normalUser.addr, address(config.tokens.usdc)), block.timestamp);
    }

    // -------------------- MINT/REDEEM REVERT -------------------- //

    function test_mint_denylisted() public {
        ILevelMintingV2Structs.Order memory order_ =
            mint_setup_inffApprovals(denylistedUser.addr, denylistedUser.addr, address(config.tokens.usdc), 10e18, 10e6);

        deal(address(config.tokens.usdc), denylistedUser.addr, 100e6);

        vm.startPrank(denylistedUser.addr);

        vm.expectRevert(ILevelMintingV2Errors.DenyListed.selector);
        levelMinting.mint(order_);
    }

    function test_mint_unsupported_asset() public {
        ILevelMintingV2Structs.Order memory order_ =
            mint_setup_inffApprovals(normalUser.addr, normalUser.addr, MAINNET_DAI, 10e18, 10e6);

        vm.startPrank(normalUser.addr);

        vm.expectRevert(ILevelMintingV2Errors.UnsupportedAsset.selector);
        levelMinting.mint(order_);
    }

    function test_redeem_unsupported_asset() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);

        vm.expectRevert(ILevelMintingV2Errors.UnsupportedAsset.selector);
        levelMinting.initiateRedeem(MAINNET_DAI, 10e18, collateralAmount);
    }

    function test_redeem_cooldown_not_met() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);

        levelMinting.initiateRedeem(address(config.tokens.usdc), 10e18, collateralAmount);
        vm.warp(block.timestamp + 20);

        vm.expectRevert(ILevelMintingV2Errors.StillInCooldown.selector);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);
    }

    function test_complete_redeem_skip_initiate() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);

        vm.expectRevert(ILevelMintingV2Errors.NoPendingRedemptions.selector);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);
    }

    function test_exceed_max_mint_block() public {
        uint256 collateralAmount = 100e6;
        uint256 mintAmount = 100e18;

        _scheduleAndExecuteAdminAction(
            address(config.users.admin),
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setMaxMintPerBlock(uint256)", 50e6)
        );

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.prank(normalUser.addr);
        vm.expectRevert(ILevelMintingV2Errors.ExceedsMaxBlockLimit.selector);
        levelMinting.mint(order_);
    }

    function test_disable_mint() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.prank(normalUser.addr);
        levelMinting.mint(order_);

        _scheduleAndExecuteAdminAction(
            address(config.users.admin),
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("disableMintRedeem()")
        );

        vm.prank(normalUser.addr);
        vm.expectRevert(ILevelMintingV2Errors.ExceedsMaxBlockLimit.selector);
        levelMinting.mint(order_);
    }

    function test_disable_initiate_redeem() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.prank(normalUser.addr);
        levelMinting.mint(order_);

        _scheduleAndExecuteAdminAction(
            address(config.users.admin),
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("disableMintRedeem()")
        );

        vm.warp(block.timestamp + 3 days + 5 minutes);

        vm.prank(normalUser.addr);
        vm.expectRevert(ILevelMintingV2Errors.ExceedsMaxBlockLimit.selector);
        levelMinting.initiateRedeem(address(config.tokens.usdc), mintAmount, collateralAmount);
    }

    function test_disable_doesnt_affect_complete_redeem() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);
        levelMinting.initiateRedeem(address(config.tokens.usdc), mintAmount, collateralAmount);

        _scheduleAndExecuteAdminAction(
            address(config.users.admin),
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("disableMintRedeem()")
        );

        vm.warp(block.timestamp + 3 days + 5 minutes);

        vm.prank(normalUser.addr);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        assertEq(config.tokens.usdc.balanceOf(normalUser.addr), INITIAL_BALANCE);
    }

    function test_exceed_max_redeem_block() public {
        uint256 collateralAmount = 100e6;
        uint256 mintAmount = 100e18;

        _scheduleAndExecuteAdminAction(
            address(config.users.admin),
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setMaxRedeemPerBlock(uint256)", 50e6)
        );

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);

        vm.expectRevert(ILevelMintingV2Errors.ExceedsMaxBlockLimit.selector);
        levelMinting.initiateRedeem(address(config.tokens.usdc), 100e18, collateralAmount); // = approx 100e6 USDC
    }

    // increasing pending redemptions multiple times without completing should revert on max redeem block
    function test_loop_exceed_max_redeem_block() public {
        uint256 collateralAmount = 100e6;
        uint256 mintAmount = 100e18;

        _scheduleAndExecuteAdminAction(
            address(config.users.admin),
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setMaxRedeemPerBlock(uint256)", 50e6)
        );

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);

        levelMinting.initiateRedeem(address(config.tokens.usdc), 25e18, 25e6);
        vm.expectRevert(ILevelMintingV2Errors.ExceedsMaxBlockLimit.selector);
        levelMinting.initiateRedeem(address(config.tokens.usdc), 26e18, 26e6);
    }

    function test_redeem_unsufficient_lvlusd_balance() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);

        vm.expectRevert();
        levelMinting.initiateRedeem(address(config.tokens.usdc), 20e18, collateralAmount);
    }

    function test_complete_redeem_twice() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_);

        levelMinting.initiateRedeem(address(config.tokens.usdc), 10e18, collateralAmount);
        vm.warp(block.timestamp + 5 minutes);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        vm.expectRevert(ILevelMintingV2Errors.NoPendingRedemptions.selector);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);
    }
    // -------------------- DEPEG -------------------- //

    // mint -> depeg up -> redeem
    // should return less collateral
    function test_depeg_initiate_and_complete_redeem_depeg_up() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_); // mints 1:1

        mockOracle.updatePriceAndDecimals(1.05e8, 8); // 1.05$
        levelMinting.initiateRedeem(address(config.tokens.usdc), 10e18, 0);

        vm.warp(block.timestamp + 5 minutes);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        assert(config.tokens.usdc.balanceOf(normalUser.addr) < INITIAL_BALANCE);
    }

    // mint -> depeg up -> redeem
    // should return samen amount of collateral
    function test_depeg_initiate_and_complete_redeem_depeg_down() public {
        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.startPrank(normalUser.addr);
        levelMinting.mint(order_); // mints 1:1

        mockOracle.updatePriceAndDecimals(950000, 8); // 0.95$
        levelMinting.initiateRedeem(address(config.tokens.usdc), 10e18, 0);

        vm.warp(block.timestamp + 5 minutes);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        vm.assertEq(config.tokens.usdc.balanceOf(normalUser.addr), INITIAL_BALANCE);
    }

    // -------------------- - -------------------- //

    // Tests what happens when cooldown duration is changed after initiating redemption
    function test_redeem_after_cooldownduration_changed() public {
        // initiated redeems should follow stored cooldown duration instead of new value

        uint256 collateralAmount = 10e6;
        uint256 mintAmount = 10e18;

        ILevelMintingV2Structs.Order memory order_ = mint_setup_inffApprovals(
            normalUser.addr, normalUser.addr, address(config.tokens.usdc), mintAmount, collateralAmount
        );

        vm.prank(normalUser.addr);
        levelMinting.mint(order_);

        bytes memory data = abi.encodeWithSignature("setCooldownDuration(uint256)", 1 minutes);
        _scheduleAdminAction(
            config.users.admin, address(config.levelContracts.adminTimelock), address(levelMinting), data
        );

        vm.warp(block.timestamp + 3 days - 1 minutes);
        vm.prank(normalUser.addr);
        levelMinting.initiateRedeem(address(config.tokens.usdc), 10e18, collateralAmount);

        vm.warp(block.timestamp + 3 days);
        _executeAdminAction(
            config.users.admin, address(config.levelContracts.adminTimelock), address(levelMinting), data
        );

        vm.warp(block.timestamp + 3 days + 1 minutes);
        vm.prank(normalUser.addr);
        levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);
    }

    function _inspectVaultBalances(string memory description, address vault) internal {
        console2.log("\n\\-----Vault balances:", description, "-----");
        address[8] memory assets = [
            address(config.tokens.usdc),
            address(config.tokens.usdt),
            address(config.tokens.aUsdc),
            address(config.tokens.aUsdt),
            address(config.morphoVaults.steakhouseUsdc.vault),
            address(config.morphoVaults.steakhouseUsdt.vault),
            address(config.morphoVaults.re7Usdc.vault),
            address(config.morphoVaults.steakhouseUsdtLite.vault)
        ];

        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];

            _printBalance(asset, vault);
        }
    }

    function _printBalance(address asset, address vault) internal {
        console2.log(vm.getLabel(asset), ERC20(asset).balanceOf(vault));
    }
}
