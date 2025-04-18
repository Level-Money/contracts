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
import {StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";

contract LevelMintingV2ReceiptUnitTests is Utils, Configurable {
    using SafeTransferLib for ERC20;

    Vm.Wallet private deployer;
    Vm.Wallet private normalUser;

    uint256 public constant INITIAL_BALANCE = 200000e6;

    LevelMintingV2 public levelMinting;
    ERC4626DelayedOracle public mockErc4626Oracle;
    MockERC4626 public mockUsdcERC4626;
    MockOracle public mockUsdcOracle;

    function setUp() public {
        forkMainnet(22134385);

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

    function test_mint_success(uint256 deposit) public {
        uint256 collateralAmount = bound(deposit, 1, mockUsdcERC4626.balanceOf(normalUser.addr));
        uint256 expectedLvlUsdAmount =
            _adjustAmount(collateralAmount, address(mockUsdcERC4626), address(config.tokens.lvlUsd));

        vm.startPrank(normalUser.addr);
        mockUsdcERC4626.approve(address(levelMinting.vaultManager().vault()), collateralAmount);
        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(mockUsdcERC4626),
            collateral_amount: collateralAmount,
            lvlusd_amount: expectedLvlUsdAmount
        });

        uint256 minted = levelMinting.mint(order);

        assertApproxEqRel(minted, expectedLvlUsdAmount, 0.0001e18, "Minted amount does not match expected amount");
    }

    function test_mint_successWithNewCollateralPriceButBeforeDelay(uint256 deposit) public {
        uint256 collateralAmount = bound(deposit, 1, mockUsdcERC4626.balanceOf(normalUser.addr));

        vm.warp(block.timestamp + 4 hours - 1);

        mockUsdcERC4626.setConvertToAssetsOutput(1.05e6);

        // Revert because delay hasn't been met
        vm.expectRevert();
        mockErc4626Oracle.update();

        vm.startPrank(normalUser.addr);

        uint256 expectedLvlUsdAmount =
            _adjustAmount(collateralAmount, address(mockUsdcERC4626), address(config.tokens.lvlUsd));

        mockUsdcERC4626.approve(address(levelMinting.vaultManager().vault()), collateralAmount);
        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(mockUsdcERC4626),
            collateral_amount: collateralAmount,
            lvlusd_amount: expectedLvlUsdAmount
        });

        // Should succeed because reverts swallow error
        uint256 minted = levelMinting.mint(order);

        assertApproxEqRel(minted, expectedLvlUsdAmount, 0.0001e18, "Minted amount does not match expected amount");
    }

    function test_mint_successWithNewCollateralPriceButAfterDelay(uint256 deposit) public {
        uint256 collateralAmount = bound(deposit, 10000, mockUsdcERC4626.balanceOf(normalUser.addr) / 2);
        vm.startPrank(normalUser.addr);

        mockUsdcERC4626.approve(address(levelMinting.vaultManager().vault()), type(uint256).max);
        mockUsdcERC4626.setConvertToAssetsOutput(1.05e6);

        uint256 epoch1 = block.timestamp;
        vm.warp(block.timestamp + 4 hours);
        uint256 epoch2 = block.timestamp;

        // expected lvlUsd amount uses the price of 1 instead of 1.05 should be applied after the next delay
        uint256 expectedLvlUsdAmount =
            _adjustAmount(collateralAmount, address(mockUsdcERC4626), address(config.tokens.lvlUsd));

        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(mockUsdcERC4626),
            collateral_amount: collateralAmount,
            lvlusd_amount: expectedLvlUsdAmount
        });

        // Check oracle before mint
        assertEq(mockErc4626Oracle.price(), 1e6, "Price does not match expected amount");
        assertEq(mockErc4626Oracle.nextPrice(), 1e6, "Next price does not match expected amount");
        assertEq(mockErc4626Oracle.updatedAt(), epoch1, "Updated at does not match expected amount");

        uint256 minted = levelMinting.mint(order);

        // Check oracle state after mint
        assertEq(mockErc4626Oracle.price(), 1e6, "Price does not match expected amount");
        assertEq(mockErc4626Oracle.nextPrice(), 1.05e6, "Next price does not match expected amount");
        assertEq(mockErc4626Oracle.updatedAt(), block.timestamp, "Updated at does not match expected amount");
        assertApproxEqRel(minted, expectedLvlUsdAmount, 0.0001e18, "Minted amount does not match expected amount");

        vm.warp(block.timestamp + 4 hours);

        // expected lvlUsdAmount should be 1.05 now because 1.05e6 was applied
        expectedLvlUsdAmount = _adjustAmount(
            _applyPercentage(collateralAmount, 1.05e18), address(mockUsdcERC4626), address(config.tokens.lvlUsd)
        );

        order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(mockUsdcERC4626),
            collateral_amount: collateralAmount,
            lvlusd_amount: expectedLvlUsdAmount
        });

        // Check oracle before mint
        assertEq(mockErc4626Oracle.price(), 1e6, "Price does not match expected amount");
        assertEq(mockErc4626Oracle.nextPrice(), 1.05e6, "Next price does not match expected amount");
        assertEq(mockErc4626Oracle.updatedAt(), epoch2, "Updated at does not match expected amount");

        minted = levelMinting.mint(order);

        assertEq(mockErc4626Oracle.price(), 1.05e6, "Price does not match expected amount");
        assertEq(mockErc4626Oracle.nextPrice(), 1.05e6, "Next price does not match expected amount");
        assertEq(mockErc4626Oracle.updatedAt(), block.timestamp, "Updated at does not match expected amount");
        assertApproxEqRel(minted, expectedLvlUsdAmount, 0.0001e18, "Minted amount does not match expected amount");
    }

    function _printOrder(ILevelMintingV2Structs.Order memory order) internal {
        console2.log("order.beneficiary", order.beneficiary);
        console2.log("order.collateral_asset", order.collateral_asset);
        console2.log("order.collateral_amount", order.collateral_amount);
        console2.log("order.lvlusd_amount", order.lvlusd_amount);
    }

    function _printOracle() internal {
        console2.log("oracle.price", mockErc4626Oracle.price());
        console2.log("oracle.nextPrice", mockErc4626Oracle.nextPrice());
        console2.log("oracle.updatedAt", mockErc4626Oracle.updatedAt());
        console2.log("now", block.timestamp);
    }
}
