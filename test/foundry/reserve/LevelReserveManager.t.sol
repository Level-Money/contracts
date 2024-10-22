// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Test, console2} from "forge-std/Test.sol";

import {SymbioticReserveManager} from "../../../src/reserve/LevelSymbioticReserveManager.sol";

import "../../../src/interfaces/IDelegationManager.sol";
import "../../../src/interfaces/ISignatureUtils.sol";

import "./ReserveBaseSetup.sol";

contract LevelReserveManagerTest is Test, ReserveBaseSetup {
    SymbioticReserveManager internal symbioticReserveManager;

    address unwhitelistedVaultDepositor;
    uint256 unwhitelistedVaultDepositorPrivateKey;
    address randomUser;
    uint256 randomUserPrivateKey;

    address public constant HOLESKY_SYMBIOTIC_VAULT_CONFIGURATOR =
        0x382e9c6fF81F07A566a8B0A3622dc85c47a891Df;

    address public constant HOLESKY_SYMBIOTIC_VAULT_FACTORY =
        0x18C659a269a7172eF78BBC19Fe47ad2237Be0590;

    uint256 public constant INITIAL_BALANCE = 100e6;
    uint256 public constant ALLOWANCE = 100000e6;

    function setUp() public override {
        super.setUp();

        (randomUser, randomUserPrivateKey) = makeAddrAndKey("randomUser");

        vm.startPrank(owner);
        symbioticReserveManager = new SymbioticReserveManager(
            IlvlUSD(address(lvlusdToken)),
            stakedlvlUSD,
            address(owner),
            address(owner)
        );
        _setupReserveManager(symbioticReserveManager);

        USDCToken.mint(INITIAL_BALANCE, address(symbioticReserveManager));
        USDTToken.transfer(address(symbioticReserveManager), INITIAL_BALANCE);

        symbioticReserveManager.approveSpender(
            address(USDCToken),
            address(levelMinting),
            ALLOWANCE
        );
        symbioticReserveManager.approveSpender(
            address(USDCToken),
            address(levelMinting),
            ALLOWANCE
        );

        symbioticReserveManager.approveSpender(
            address(lvlusdToken),
            address(stakedlvlUSD),
            ALLOWANCE * 1e18
        );

        stakedlvlUSD.grantRole(
            keccak256("REWARDER_ROLE"),
            address(symbioticReserveManager)
        );
    }

    function testDepositToLevelMinting(uint256 depositAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= INITIAL_BALANCE);

        vm.startPrank(managerAgent);
        symbioticReserveManager.depositToLevelMinting(
            address(USDCToken),
            depositAmount
        );
        assertEq(
            USDCToken.balanceOf(address(levelMinting)),
            depositAmount,
            "Incorrect levelMinting balance."
        );
    }

    function testDepositToStakedLvlusd(
        uint256 mintAmount,
        uint256 rewardAmount
    ) public {
        vm.assume(mintAmount > 0);
        vm.assume(rewardAmount > 0);
        vm.assume(mintAmount <= INITIAL_BALANCE);

        vm.startPrank(owner);

        // Assert collateral balances
        assertEq(
            USDCToken.balanceOf(address(symbioticReserveManager)),
            INITIAL_BALANCE,
            "Incorrect USDCToken balance."
        );

        symbioticReserveManager.mintlvlUSD(address(USDCToken), mintAmount);

        // Assert collateral balances
        assertEq(
            USDCToken.balanceOf(address(symbioticReserveManager)),
            INITIAL_BALANCE,
            "Incorrect USDCToken balance."
        );

        uint256 lvlUsdBalance = lvlusdToken.balanceOf(
            address(symbioticReserveManager)
        );

        vm.assume(rewardAmount <= lvlUsdBalance);

        symbioticReserveManager.rewardStakedlvlUSD(rewardAmount);

        // Assert Level USD balances
        assertEq(
            lvlusdToken.balanceOf(address(stakedlvlUSD)),
            rewardAmount,
            "Incorrect StakedlvlUSD balance."
        );
        assertEq(
            lvlusdToken.balanceOf(address(symbioticReserveManager)),
            lvlUsdBalance - rewardAmount,
            "Incorrect SymbioticReserveManager balance."
        );
    }

    function testTransferErc20(uint256 transferAmount) public {
        vm.assume(transferAmount > 0);
        vm.assume(transferAmount <= INITIAL_BALANCE);

        vm.startPrank(owner);

        symbioticReserveManager.setAllowlist(randomUser, true);
        symbioticReserveManager.transferERC20(
            address(USDCToken),
            randomUser,
            transferAmount
        );
        assertEq(
            USDCToken.balanceOf(randomUser),
            transferAmount,
            "Incorrect USDCToken balance."
        );
    }

    function testTransferErc20RevertsIfNotAllowlisted() public {
        vm.startPrank(owner);

        vm.expectRevert();
        symbioticReserveManager.transferERC20(
            address(USDCToken),
            randomUser,
            1
        );
    }

    function testTransferErc20ToFormerlyAllowlisted() public {
        vm.startPrank(owner);

        symbioticReserveManager.setAllowlist(randomUser, true);
        symbioticReserveManager.setAllowlist(randomUser, false);

        vm.expectRevert();
        symbioticReserveManager.transferERC20(
            address(USDCToken),
            randomUser,
            1
        );
    }
}
