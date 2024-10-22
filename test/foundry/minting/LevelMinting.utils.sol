// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/* solhint-disable func-name-mixedcase  */

import "./MintingBaseSetup.sol";
import "forge-std/console.sol";

// These functions are reused across multiple files
contract LevelMintingUtils is MintingBaseSetup {
    function maxMint_perBlock_exceeded_revert(
        uint256 excessiveMintAmount
    ) public {
        // This amount is always greater than the allowed max mint per block
        vm.assume(excessiveMintAmount > LevelMintingContract.maxMintPerBlock());
        (
            ILevelMinting.Order memory order,
            ILevelMinting.Route memory route
        ) = mint_setup(excessiveMintAmount, _DAIToDeposit, false);

        vm.prank(minter);
        vm.expectRevert(MaxMintPerBlockExceeded);
        LevelMintingContract.mint(order, route);

        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "The beneficiary balance should be 0"
        );
        assertEq(
            DAIToken.balanceOf(address(LevelMintingContract)),
            0,
            "The level minting DAI balance should be 0"
        );
        assertEq(
            DAIToken.balanceOf(benefactor),
            _DAIToDeposit,
            "Mismatch in DAI balance"
        );
    }

    function maxRedeem_perBlock_exceeded_revert(
        uint256 excessiveRedeemAmount
    ) public {
        // Set the max mint per block to the same value as the max redeem in order to get to the redeem
        vm.startPrank(owner);
        LevelMintingContract.setMaxMintPerBlock(excessiveRedeemAmount);

        ILevelMinting.Order memory redeemOrder = redeem_setup(
            excessiveRedeemAmount,
            _DAIToDeposit,
            false
        );
        vm.stopPrank();
        vm.startPrank(redeemer);
        vm.expectRevert(MaxRedeemPerBlockExceeded);
        LevelMintingContract.redeem(redeemOrder);

        assertEq(
            DAIToken.balanceOf(address(LevelMintingContract)),
            _DAIToDeposit,
            "Mismatch in DAI balance"
        );
        assertEq(DAIToken.balanceOf(beneficiary), 0, "Mismatch in DAI balance");
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            excessiveRedeemAmount,
            "Mismatch in lvlUSD balance"
        );

        vm.stopPrank();
    }

    function executeMint() public {
        (
            ILevelMinting.Order memory order,
            ILevelMinting.Route memory route
        ) = mint_setup(_lvlusdToMint, _DAIToDeposit, false);

        vm.prank(minter);
        LevelMintingContract.mint(order, route);
    }

    function executeRedeem() public {
        ILevelMinting.Order memory redeemOrder = redeem_setup(
            _lvlusdToMint,
            _DAIToDeposit,
            false
        );
        vm.prank(redeemer);
        LevelMintingContract.redeem(redeemOrder);
    }
}
