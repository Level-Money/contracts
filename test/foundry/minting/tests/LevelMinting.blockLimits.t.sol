// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/* solhint-disable func-name-mixedcase  */

import "../LevelMinting.utils.sol";

contract LevelMintingBlockLimitsTest is LevelMintingUtils {
    /**
     * Max mint per block tests
     */

    // Ensures that the minted per block amount raises accordingly
    // when multiple mints are performed
    function test_multiple_mints() public {
        uint256 maxMintAmount = LevelMintingContract.maxMintPerBlock();
        uint256 firstMintAmount = maxMintAmount / 4;
        uint256 secondMintAmount = maxMintAmount / 2;
        (
            ILevelMinting.Order memory aOrder,
            ILevelMinting.Route memory aRoute
        ) = mint_setup(firstMintAmount, _stETHToDeposit, false);

        vm.prank(minter);
        LevelMintingContract.mint(aOrder, aRoute);

        vm.prank(owner);
        stETHToken.mint(_stETHToDeposit, benefactor);

        (
            ILevelMinting.Order memory bOrder,
            ILevelMinting.Route memory bRoute
        ) = mint_setup(secondMintAmount, _stETHToDeposit, true);
        vm.prank(minter);
        LevelMintingContract.mint(bOrder, bRoute);

        assertEq(
            LevelMintingContract.mintedPerBlock(block.number),
            firstMintAmount + secondMintAmount,
            "Incorrect minted amount"
        );
        assertTrue(
            LevelMintingContract.mintedPerBlock(block.number) < maxMintAmount,
            "Mint amount exceeded without revert"
        );
    }

    function test_fuzz_maxMint_perBlock_exceeded_revert(
        uint256 excessiveMintAmount
    ) public {
        // This amount is always greater than the allowed max mint per block
        vm.assume(excessiveMintAmount > LevelMintingContract.maxMintPerBlock());

        maxMint_perBlock_exceeded_revert(excessiveMintAmount);
    }

    function test_fuzz_mint_maxMint_perBlock_exceeded_revert(
        uint256 excessiveMintAmount
    ) public {
        vm.assume(excessiveMintAmount > LevelMintingContract.maxMintPerBlock());
        (
            ILevelMinting.Order memory mintOrder,
            ILevelMinting.Route memory route
        ) = mint_setup(excessiveMintAmount, _stETHToDeposit, false);

        // maker
        vm.startPrank(minter);
        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
        assertEq(lvlusdToken.balanceOf(beneficiary), 0);

        vm.expectRevert(MaxMintPerBlockExceeded);
        // minter passes in permit signature data
        LevelMintingContract.mint(mintOrder, route);

        assertEq(
            stETHToken.balanceOf(benefactor),
            _stETHToDeposit,
            "The benefactor stEth balance should be the same as the minted stEth"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "The beneficiary lvlUSD balance should be 0"
        );
    }

    function test_fuzz_nextBlock_mint_is_zero(uint256 mintAmount) public {
        vm.assume(
            mintAmount < LevelMintingContract.maxMintPerBlock() &&
                mintAmount > 0
        );
        (
            ILevelMinting.Order memory order,
            ILevelMinting.Route memory route
        ) = mint_setup(_lvlusdToMint, _stETHToDeposit, false);

        vm.prank(minter);
        LevelMintingContract.mint(order, route);

        vm.roll(block.number + 1);

        assertEq(
            LevelMintingContract.mintedPerBlock(block.number),
            0,
            "The minted amount should reset to 0 in the next block"
        );
    }

    function test_fuzz_maxMint_perBlock_setter(
        uint256 newMaxMintPerBlock
    ) public {
        vm.assume(newMaxMintPerBlock > 0);

        uint256 oldMaxMintPerBlock = LevelMintingContract.maxMintPerBlock();

        vm.prank(owner);
        vm.expectEmit();
        emit MaxMintPerBlockChanged(oldMaxMintPerBlock, newMaxMintPerBlock);

        LevelMintingContract.setMaxMintPerBlock(newMaxMintPerBlock);

        assertEq(
            LevelMintingContract.maxMintPerBlock(),
            newMaxMintPerBlock,
            "The max mint per block setter failed"
        );
    }

    /**
     * Max redeem per block tests
     */

    // Ensures that the redeemed per block amount raises accordingly
    // when multiple mints are performed
    function test_multiple_redeem() public {
        uint256 maxRedeemAmount = LevelMintingContract.maxRedeemPerBlock();
        uint256 firstRedeemAmount = maxRedeemAmount / 4;
        uint256 secondRedeemAmount = maxRedeemAmount / 2;

        ILevelMinting.Order memory redeemOrder = redeem_setup(
            firstRedeemAmount,
            _stETHToDeposit,
            false
        );

        vm.prank(redeemer);
        LevelMintingContract.redeem(redeemOrder);

        vm.prank(owner);
        stETHToken.mint(_stETHToDeposit, benefactor);

        ILevelMinting.Order memory bRedeemOrder = redeem_setup(
            secondRedeemAmount,
            _stETHToDeposit,
            true
        );

        vm.prank(redeemer);
        LevelMintingContract.redeem(bRedeemOrder);

        assertEq(
            LevelMintingContract.mintedPerBlock(block.number),
            firstRedeemAmount + secondRedeemAmount,
            "Incorrect minted amount"
        );
        assertTrue(
            LevelMintingContract.redeemedPerBlock(block.number) <
                maxRedeemAmount,
            "Redeem amount exceeded without revert"
        );
    }

    function test_fuzz_maxRedeem_perBlock_exceeded_revert(
        uint256 excessiveRedeemAmount
    ) public {
        // This amount is always greater than the allowed max redeem per block
        vm.assume(
            excessiveRedeemAmount > LevelMintingContract.maxRedeemPerBlock()
        );

        // Set the max mint per block to the same value as the max redeem in order to get to the redeem
        vm.prank(owner);
        LevelMintingContract.setMaxMintPerBlock(excessiveRedeemAmount);

        ILevelMinting.Order memory redeemOrder = redeem_setup(
            excessiveRedeemAmount,
            _stETHToDeposit,
            false
        );

        vm.startPrank(redeemer);
        vm.expectRevert(MaxRedeemPerBlockExceeded);
        LevelMintingContract.redeem(redeemOrder);

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            _stETHToDeposit,
            "Mismatch in stETH balance"
        );
        assertEq(
            stETHToken.balanceOf(beneficiary),
            0,
            "Mismatch in stETH balance"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            excessiveRedeemAmount,
            "Mismatch in lvlUSD balance"
        );

        vm.stopPrank();
    }

    function test_fuzz_nextBlock_redeem_is_zero(uint256 redeemAmount) public {
        vm.assume(
            redeemAmount < LevelMintingContract.maxRedeemPerBlock() &&
                redeemAmount > 0
        );
        ILevelMinting.Order memory redeemOrder = redeem_setup(
            redeemAmount,
            _stETHToDeposit,
            false
        );

        vm.startPrank(redeemer);
        LevelMintingContract.redeem(redeemOrder);

        vm.roll(block.number + 1);

        assertEq(
            LevelMintingContract.redeemedPerBlock(block.number),
            0,
            "The redeemed amount should reset to 0 in the next block"
        );
        vm.stopPrank();
    }

    function test_fuzz_maxRedeem_perBlock_setter(
        uint256 newMaxRedeemPerBlock
    ) public {
        vm.assume(newMaxRedeemPerBlock > 0);

        uint256 oldMaxRedeemPerBlock = LevelMintingContract.maxMintPerBlock();

        vm.prank(owner);
        vm.expectEmit();
        emit MaxRedeemPerBlockChanged(
            oldMaxRedeemPerBlock,
            newMaxRedeemPerBlock
        );
        LevelMintingContract.setMaxRedeemPerBlock(newMaxRedeemPerBlock);

        assertEq(
            LevelMintingContract.maxRedeemPerBlock(),
            newMaxRedeemPerBlock,
            "The max redeem per block setter failed"
        );
    }
}
