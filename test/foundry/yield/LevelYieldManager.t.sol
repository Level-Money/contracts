// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/* solhint-disable func-name-mixedcase  */
import "../minting/MintingBaseSetup.sol";

contract LevelYieldManagerTest is MintingBaseSetup {
    function setUp() public override {
        vm.startPrank(owner);
        super.setUp();
        vm.stopPrank();
    }

    // This test demonstrates the conversion USDC -> aUSDC -> waUSDC via aaveYieldManager
    function testDepositForYieldAndWithdraw() public {
        vm.startPrank(owner);
        uint amount = 10000000000000;
        USDCToken.mint(amount);
        aaveYieldManager.approveSpender(
            address(USDCToken),
            address(mockAavePool),
            amount
        );
        USDCToken.approve(address(aaveYieldManager), amount);
        aaveYieldManager.depositForYield(address(USDCToken), 10);
        assertEq(
            waUSDC.balanceOf(address(owner)),
            10,
            "Incorrect waUSDC balance."
        );
        waUSDC.approve(address(aaveYieldManager), amount);
        aaveYieldManager.withdraw(address(USDCToken), 10);
        assertEq(
            waUSDC.balanceOf(address(owner)),
            0,
            "Incorrect waUSDC balance."
        );
        assertEq(
            USDCToken.balanceOf(address(owner)),
            amount,
            "Incorrect USDC balance."
        );
    }

    // test deposit and withdraw for token with 18 decimals
    function testDepositForYieldAndWithdrawMoreDecimals() public {
        vm.startPrank(owner);
        uint amount = 10000000000000;
        DAIToken.mint(amount);
        aaveYieldManager.approveSpender(
            address(DAIToken),
            address(mockAavePool),
            amount
        );
        DAIToken.approve(address(aaveYieldManager), amount);
        aaveYieldManager.depositForYield(address(DAIToken), 10);
        assertEq(
            waDAIToken.balanceOf(address(owner)),
            10,
            "Incorrect waDAIToken balance."
        );
        waDAIToken.approve(address(aaveYieldManager), amount);
        aaveYieldManager.withdraw(address(DAIToken), 10);
        assertEq(
            waDAIToken.balanceOf(address(owner)),
            0,
            "Incorrect waDAIToken balance."
        );
        assertEq(
            DAIToken.balanceOf(address(owner)),
            amount,
            "Incorrect DAIToken balance."
        );
    }

    // test reserve manager deposit for yield and withdraw functions, which call
    // the corresponding functions in yield managers
    function testReserveManagerDepositForYield() public {
        vm.startPrank(owner);
        uint amount = 10000000000000;
        uint transferAmount = 99999999;
        USDCToken.mint(amount);
        USDCToken.transfer(address(eigenlayerReserveManager), transferAmount);
        aaveYieldManager.approveSpender(
            address(USDCToken),
            address(mockAavePool),
            amount
        );
        eigenlayerReserveManager.approveSpender(
            address(USDCToken),
            address(aaveYieldManager),
            amount
        );
        eigenlayerReserveManager.approveSpender(
            address(waUSDC),
            address(aaveYieldManager),
            amount
        );

        vm.stopPrank();
        vm.startPrank(managerAgent);
        eigenlayerReserveManager.depositForYield(address(USDCToken), 10);
        assertEq(
            waUSDC.balanceOf(address(eigenlayerReserveManager)),
            10,
            "Incorrect waUSDC balance."
        );
        eigenlayerReserveManager.withdrawFromYieldManager(
            address(USDCToken),
            10
        );
        assertEq(
            waUSDC.balanceOf(address(eigenlayerReserveManager)),
            0,
            "Incorrect waUSDC balance."
        );
        assertEq(
            USDCToken.balanceOf(address(eigenlayerReserveManager)),
            transferAmount,
            "Incorrect USDC balance."
        );
    }

    // test that aave yield is accrued to ERC20Wrapper (in this case waUSDC)
    function testAaveAccrueInterest() public {
        vm.startPrank(owner);
        uint amount = 10000000000000;
        uint transferAmount = 99999999;
        USDCToken.mint(amount);
        USDCToken.transfer(address(eigenlayerReserveManager), transferAmount);
        aaveYieldManager.approveSpender(
            address(USDCToken),
            address(mockAavePool),
            amount
        );
        eigenlayerReserveManager.approveSpender(
            address(USDCToken),
            address(aaveYieldManager),
            amount
        );
        vm.stopPrank();

        vm.startPrank(managerAgent);
        eigenlayerReserveManager.depositForYield(address(USDCToken), 10);
        vm.stopPrank();
        assertEq(
            waUSDC.balanceOf(address(eigenlayerReserveManager)),
            10,
            "Incorrect waUSDC balance."
        );

        vm.startPrank(owner);
        // // rebase
        aUSDC.accrueInterest(1000); // increase aUSDC balances by 10%

        // withdraw extra tokens from ERC20Wrapper to bob
        waUSDC.recover(address(bob));
        assertEq(
            waUSDC.balanceOf(address(bob)),
            1, // mint 1 waUSDC token to bob
            "Incorrect waUSDC balance."
        );
    }
}
