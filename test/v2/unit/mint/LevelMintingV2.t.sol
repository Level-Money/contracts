// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {stdStorage, StdStorage, Test, Vm} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {
    ILevelMintingV2,
    ILevelMintingV2Structs,
    ILevelMintingV2Errors
} from "@level/src/v2/interfaces/level/ILevelMintingV2.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {MockOracle} from "@level/test/v2/mocks/MockOracle.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {MockERC4626} from "@level/test/v2/mocks/MockERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";

import {ERC4626DelayedOracle} from "@level/src/v2/oracles/ERC4626DelayedOracle.sol";
import {StrategyCategory, StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {Silo} from "@level/src/v2/usd/Silo.sol";
import {MockVaultManager} from "@level/test/v2/mocks/MockVaultManager.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";

contract LevelMintingV2ReceiptUnitTests is Utils, Configurable {
    using SafeTransferLib for ERC20;
    using MathLib for uint256;

    Vm.Wallet private deployer;
    Vm.Wallet private normalUser;

    uint256 public constant INITIAL_BALANCE = 200000e6;

    LevelMintingV2 public levelMinting;
    ERC4626DelayedOracle public mockErc4626Oracle;
    MockERC4626 public mockUsdcERC4626;
    MockOracle public mockUsdcOracle;

    function setUp() public {
        forkMainnet(22331729);

        deployer = vm.createWallet("deployer");
        normalUser = vm.createWallet("normalUser");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        mockUsdcOracle = new MockOracle(1e8, 8);
        mockUsdcERC4626 = new MockERC4626(IERC20(address(config.tokens.usdc)));

        vm.label(address(mockUsdcERC4626), "mockUsdcERC4626");
        vm.label(address(mockUsdcOracle), "mockUsdcOracle");
        mockUsdcERC4626.setConvertToAssetsOutput(10 ** mockUsdcERC4626.decimals());

        // Seed mock erc4626
        deal(address(config.tokens.usdc), normalUser.addr, INITIAL_BALANCE);

        vm.startPrank(normalUser.addr);
        config.tokens.usdc.approve(address(mockUsdcERC4626), config.tokens.usdc.balanceOf(normalUser.addr));

        mockUsdcERC4626.deposit(config.tokens.usdc.balanceOf(normalUser.addr), normalUser.addr);
        vm.stopPrank();

        mockErc4626Oracle =
            config.levelContracts.erc4626OracleFactory.createDelayed(IERC4626(address(mockUsdcERC4626)), 4 hours);

        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = address(mockUsdcERC4626);

        address[] memory targets = new address[](8);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.levelMintingV2);
        targets[2] = address(config.levelContracts.levelMintingV2);
        targets[3] = address(config.levelContracts.levelMintingV2);
        targets[4] = address(config.levelContracts.levelMintingV2);
        targets[5] = address(config.levelContracts.levelMintingV2);
        targets[6] = address(config.levelContracts.vaultManager);
        targets[7] = address(config.levelContracts.vaultManager);

        bytes[] memory payloads = new bytes[](8);
        payloads[0] =
            abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(normalUser.addr), REDEEMER_ROLE, true);
        payloads[1] = abi.encodeWithSignature("addMintableAsset(address)", address(mockUsdcERC4626));
        payloads[2] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(mockUsdcERC4626), address(mockErc4626Oracle), true
        );
        payloads[3] = abi.encodeWithSignature("setHeartBeat(address,uint256)", address(mockUsdcERC4626), 1 days);
        payloads[4] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdc), address(mockUsdcOracle), true
        );
        payloads[5] = abi.encodeWithSignature("setHeartBeat(address,uint256)", address(config.tokens.usdc), 1 days);
        payloads[6] = abi.encodeWithSelector(
            VaultManager.addAssetStrategy.selector,
            mockUsdcERC4626.asset(),
            address(mockUsdcERC4626),
            StrategyConfig({
                category: StrategyCategory.MORPHO,
                baseCollateral: config.tokens.usdc,
                receiptToken: ERC20(address(mockUsdcERC4626)),
                oracle: AggregatorV3Interface(address(mockErc4626Oracle)),
                depositContract: address(mockUsdcERC4626),
                withdrawContract: address(mockUsdcERC4626),
                heartbeat: 1 days
            })
        );
        payloads[7] = abi.encodeWithSignature(
            "setDefaultStrategies(address,address[])", mockUsdcERC4626.asset(), defaultStrategies
        );

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        vm.startPrank(config.users.admin);
        lvlUSD _lvlUSD = lvlUSD(address(config.tokens.lvlUsd));
        _lvlUSD.setMinter(address(config.levelContracts.levelMintingV2));
        vm.stopPrank();

        // Need to update because we changed the timestamp from the admin action
        mockErc4626Oracle.update();
        levelMinting = LevelMintingV2(address(config.levelContracts.levelMintingV2));
    }

    function test_removeMintableAsset_succeeds() public {
        vm.startPrank(config.users.admin);
        levelMinting.removeMintableAsset(address(mockUsdcERC4626));
        vm.stopPrank();

        assertEq(levelMinting.mintableAssets(address(mockUsdcERC4626)), false);
    }

    function test_removeMintableAsset_failsIfNotAdmin() public {
        vm.startPrank(normalUser.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.removeMintableAsset(address(mockUsdcERC4626));
        vm.stopPrank();
    }

    function test_removeRedeemableAsset_succeeds() public {
        vm.startPrank(config.users.admin);
        levelMinting.removeRedeemableAsset(address(mockUsdcERC4626));
        vm.stopPrank();

        assertEq(levelMinting.redeemableAssets(address(mockUsdcERC4626)), false);
    }

    function test_removeRedeemableAsset_failsIfNotAdmin() public {
        vm.startPrank(normalUser.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.removeRedeemableAsset(address(mockUsdcERC4626));
        vm.stopPrank();
    }

    function test_addMintableAsset_succeeds() public {
        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addMintableAsset(address)", address(mockUsdcERC4626))
        );

        assertEq(levelMinting.mintableAssets(address(mockUsdcERC4626)), true);
    }

    function test_addRedeemableAsset_succeeds() public {
        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addRedeemableAsset(address)", address(mockUsdcERC4626))
        );

        assertEq(levelMinting.redeemableAssets(address(mockUsdcERC4626)), true);
    }

    function test_addMintableAsset_failsIfNotAdmin() public {
        vm.expectRevert();
        _scheduleAdminAction(
            normalUser.addr,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addMintableAsset(address)", address(mockUsdcERC4626))
        );
    }

    function test_addRedeemableAsset_failsIfNotAdmin() public {
        vm.expectRevert();
        _scheduleAdminAction(
            normalUser.addr,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addRedeemableAsset(address)", address(mockUsdcERC4626))
        );
    }

    function test_addMintableAsset_failsIfTimelockDelayHasntPassed() public {
        _scheduleAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addMintableAsset(address)", address(mockUsdcERC4626))
        );

        vm.warp(block.timestamp + 1 days);

        vm.expectRevert();
        _executeAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addMintableAsset(address)", address(mockUsdcERC4626))
        );
    }

    function test_addRedeemableAsset_failsIfTimelockDelayHasntPassed() public {
        _scheduleAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addRedeemableAsset(address)", address(mockUsdcERC4626))
        );

        vm.warp(block.timestamp + 1 days);

        vm.expectRevert();
        _executeAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("addRedeemableAsset(address)", address(mockUsdcERC4626))
        );
    }

    function test_silo_cannotBeCalledByNormalUser() public {
        vm.startPrank(normalUser.addr);

        Silo silo = levelMinting.silo();
        vm.expectRevert();
        silo.withdraw(normalUser.addr, address(config.tokens.usdc), 100);
        vm.stopPrank();
    }

    function test_depositDefaultFailure_doesNotBlockMint() public {
        deal(address(config.tokens.usdc), normalUser.addr, 100);

        MockVaultManager mockVaultManager = new MockVaultManager(address(config.levelContracts.boringVault));
        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setVaultManager(address)", address(mockVaultManager))
        );

        mockVaultManager.setShouldDepositDefaultRevert(true);

        vm.startPrank(normalUser.addr);
        config.tokens.usdc.approve(address(mockVaultManager.vault()), 100);
        levelMinting.mint(
            ILevelMintingV2Structs.Order({
                beneficiary: normalUser.addr,
                collateral_asset: address(config.tokens.usdc),
                collateral_amount: 100,
                lvlusd_amount: 0
            })
        );

        /// Mint should succeed despite depositDefault reverting
        assertEq(
            config.tokens.lvlUsd.balanceOf(normalUser.addr),
            MathLib.convertDecimalsDown(100, config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals())
        );
        assertEq(config.tokens.usdc.balanceOf(address(config.levelContracts.boringVault)), 100);
    }

    function test_mint_vaultManagerFailureDoesNotBlockMints() public {
        uint256 collateralAmount = 100;
        deal(address(config.tokens.usdc), normalUser.addr, collateralAmount);

        MockVaultManager mockVaultManager = new MockVaultManager(address(config.levelContracts.boringVault));
        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setVaultManager(address)", address(mockVaultManager))
        );

        mockVaultManager.setShouldDepositDefaultRevert(true);

        vm.startPrank(normalUser.addr);
        config.tokens.usdc.approve(address(mockVaultManager.vault()), collateralAmount);
        levelMinting.mint(
            ILevelMintingV2Structs.Order({
                beneficiary: normalUser.addr,
                collateral_asset: address(config.tokens.usdc),
                collateral_amount: collateralAmount,
                lvlusd_amount: 0
            })
        );

        uint256 lvlUsdAmount =
            collateralAmount.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals());

        // Since deposit default reverted, the collateral was not deployed
        // Since there's enough undeployed collateral to meet redemptions, we should
        // still be able to redeem even if withdrawDefault reverts
        mockVaultManager.setShouldWithdrawDefaultRevert(true);

        config.tokens.lvlUsd.approve(address(levelMinting), lvlUsdAmount);
        levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdAmount, 0);

        /// Redemptions should still succeed despite withdrawDefault reverting
        assertEq(config.tokens.lvlUsd.balanceOf(normalUser.addr), 0);
    }

    function test_redeem_vaultManagerFailureDoesntBlockFailureWithEnoughCollateral() public {
        uint256 collateralAmount = 100;
        uint256 sharesAmount = collateralAmount.convertDecimalsDown(
            config.tokens.usdc.decimals(), config.levelContracts.boringVault.decimals()
        );
        uint256 lvlUsdAmount =
            collateralAmount.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals());

        vm.startPrank(normalUser.addr);

        deal(address(config.tokens.usdc), address(config.levelContracts.boringVault), collateralAmount);
        deal(address(config.levelContracts.boringVault), address(config.levelContracts.boringVault), sharesAmount);
        deal(address(config.tokens.lvlUsd), normalUser.addr, lvlUsdAmount);

        vm.stopPrank();

        MockVaultManager mockVaultManager = new MockVaultManager(address(config.levelContracts.boringVault));
        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setVaultManager(address)", address(mockVaultManager))
        );

        vm.startPrank(normalUser.addr);
        mockVaultManager.setShouldWithdrawDefaultRevert(true);

        config.tokens.lvlUsd.approve(address(levelMinting), lvlUsdAmount);

        levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdAmount, 0);

        // Redemptions should succeed
        assertEq(config.tokens.lvlUsd.balanceOf(normalUser.addr), 0);
    }

    function test_redeem_vaultManagerFailureBlocksRedemptions() public {
        uint256 collateralAmount = 100;
        uint256 lvlUsdAmount =
            collateralAmount.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals());

        vm.startPrank(normalUser.addr);

        deal(address(config.tokens.lvlUsd), normalUser.addr, lvlUsdAmount);
        vm.stopPrank();

        MockVaultManager mockVaultManager = new MockVaultManager(address(config.levelContracts.boringVault));
        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setVaultManager(address)", address(mockVaultManager))
        );

        vm.startPrank(normalUser.addr);
        mockVaultManager.setShouldWithdrawDefaultRevert(true);

        config.tokens.lvlUsd.approve(address(levelMinting), lvlUsdAmount);

        vm.expectRevert("MockVaultManager: withdrawDefault revert");
        levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdAmount, 0);

        // Redemptions should not succeed
        assertEq(config.tokens.lvlUsd.balanceOf(normalUser.addr), lvlUsdAmount);
    }

    function test_completeRedeem_succeedsEvenIfRedemptionAssetIsRemoved() public {
        uint256 collateralAmount = 100;
        uint256 sharesAmount = collateralAmount.convertDecimalsDown(
            config.tokens.usdc.decimals(), config.levelContracts.boringVault.decimals()
        );
        uint256 lvlUsdAmount =
            collateralAmount.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals());

        vm.startPrank(normalUser.addr);

        deal(address(config.tokens.usdc), address(config.levelContracts.boringVault), collateralAmount);
        deal(address(config.levelContracts.boringVault), address(config.levelContracts.boringVault), sharesAmount);
        deal(address(config.tokens.lvlUsd), normalUser.addr, lvlUsdAmount);

        vm.stopPrank();

        MockVaultManager mockVaultManager = new MockVaultManager(address(config.levelContracts.boringVault));
        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("setVaultManager(address)", address(mockVaultManager))
        );

        vm.startPrank(normalUser.addr);
        mockVaultManager.setShouldWithdrawDefaultRevert(true);

        config.tokens.lvlUsd.approve(address(levelMinting), lvlUsdAmount);
        (, uint256 pendingRedemptionAmount) = levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdAmount, 0);

        // Initiate redeem should succeed
        assertEq(config.tokens.lvlUsd.balanceOf(normalUser.addr), 0);
        assertEq(levelMinting.pendingRedemption(normalUser.addr, address(config.tokens.usdc)), pendingRedemptionAmount);

        vm.stopPrank();

        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(levelMinting),
            abi.encodeWithSignature("removeRedeemableAsset(address)", address(config.tokens.usdc))
        );

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(normalUser.addr);
        // Complete redeem should succeed
        uint256 redeemedAmount = levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        assertEq(config.tokens.usdc.balanceOf(normalUser.addr), redeemedAmount);
    }

    function test_completeRedeem_failsIfAddressIsDenylisted() public {
        uint256 collateralAmount = 100;
        uint256 sharesAmount = collateralAmount.convertDecimalsDown(
            config.tokens.usdc.decimals(), config.levelContracts.boringVault.decimals()
        );
        uint256 lvlUsdAmount =
            collateralAmount.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals());

        vm.startPrank(normalUser.addr);

        deal(address(config.tokens.usdc), address(config.levelContracts.boringVault), collateralAmount);
        deal(address(config.levelContracts.boringVault), address(config.levelContracts.boringVault), sharesAmount);
        deal(address(config.tokens.lvlUsd), normalUser.addr, lvlUsdAmount);

        config.tokens.lvlUsd.approve(address(levelMinting), lvlUsdAmount);
        (, uint256 pendingRedemptionAmount) = levelMinting.initiateRedeem(address(config.tokens.usdc), lvlUsdAmount, 0);

        // Initiate redeem should succeed
        assertEq(config.tokens.lvlUsd.balanceOf(normalUser.addr), 0);
        assertEq(levelMinting.pendingRedemption(normalUser.addr, address(config.tokens.usdc)), pendingRedemptionAmount);

        vm.stopPrank();

        lvlUSD _lvlUSD = lvlUSD(address(config.tokens.lvlUsd));
        vm.startPrank(config.users.admin);
        _lvlUSD.addToDenylist(normalUser.addr);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(normalUser.addr);
        // Complete redeem should fail
        vm.expectRevert(ILevelMintingV2Errors.DenyListed.selector);
        uint256 redeemedAmount = levelMinting.completeRedeem(address(config.tokens.usdc), normalUser.addr);

        assertEq(config.tokens.usdc.balanceOf(normalUser.addr), redeemedAmount);
    }
}
