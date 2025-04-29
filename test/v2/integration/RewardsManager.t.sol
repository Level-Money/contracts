// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test, Vm} from "forge-std/Test.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {StrategyConfig, StrategyLib, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {IRewardsManagerErrors} from "@level/src/v2/interfaces/level/IRewardsManager.sol";
import {MockOracle} from "@level/test/v2/mocks/MockOracle.sol";

contract RewardsManagerMainnetTests is Utils, Configurable {
    using SafeTransferLib for ERC20;
    using VaultLib for BoringVault;
    using MathLib for uint256;

    Vm.Wallet private deployer;
    Vm.Wallet private strategist;

    RewardsManager public rewardsManager;
    VaultManager public vaultManager;
    MockOracle public mockOracle;

    uint256 public constant INITIAL_BALANCE = 100_000_000e6;
    uint256 public constant INITIAL_SHARES = 200_000_000e18;

    address[] public assets;

    function setUp() public {
        forkMainnet(22305203);

        deployer = vm.createWallet("deployer");
        strategist = vm.createWallet("strategist");

        DeployLevel deployScript = new DeployLevel();

        // Deploy

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        mockOracle = new MockOracle(1e8, 8);

        // Setup strategist
        address[] memory targets = new address[](4);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.rolesAuthority);
        targets[2] = address(config.levelContracts.rewardsManager);
        targets[3] = address(config.levelContracts.rewardsManager);

        bytes[] memory payloads = new bytes[](4);
        payloads[0] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, STRATEGIST_ROLE, true);
        payloads[1] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, REWARDER_ROLE, true);
        payloads[2] =
            abi.encodeWithSignature("updateOracle(address,address)", address(config.tokens.usdc), address(mockOracle));
        payloads[3] =
            abi.encodeWithSignature("updateOracle(address,address)", address(config.tokens.usdt), address(mockOracle));

        _scheduleAndExecuteAdminActionBatch(
            address(config.users.admin), address(config.levelContracts.adminTimelock), targets, payloads
        );

        deal(address(config.tokens.usdc), address(strategist.addr), INITIAL_BALANCE);
        deal(address(config.tokens.usdt), address(strategist.addr), INITIAL_BALANCE);

        deal(address(config.tokens.usdc), address(config.levelContracts.boringVault), INITIAL_BALANCE);
        deal(address(config.tokens.usdt), address(config.levelContracts.boringVault), INITIAL_BALANCE);

        deal(address(config.levelContracts.boringVault), address(config.levelContracts.boringVault), INITIAL_SHARES);

        // Get som aUsdc and aUsdt
        vm.startPrank(strategist.addr);
        ERC20(config.tokens.usdc).safeApprove(address(config.periphery.aaveV3), INITIAL_BALANCE);
        ERC20(config.tokens.usdt).safeApprove(address(config.periphery.aaveV3), INITIAL_BALANCE);
        config.periphery.aaveV3.supply(address(config.tokens.usdc), INITIAL_BALANCE, strategist.addr, 0);
        config.periphery.aaveV3.supply(address(config.tokens.usdt), INITIAL_BALANCE, strategist.addr, 0);
        vm.stopPrank();

        assets = new address[](2);
        assets[0] = address(config.tokens.usdc);
        assets[1] = address(config.tokens.usdt);

        rewardsManager = config.levelContracts.rewardsManager;
        vaultManager = config.levelContracts.vaultManager;
    }

    function test_tooHighYieldAmount_reverts() public {
        vm.startPrank(strategist.addr);

        vm.expectRevert(IRewardsManagerErrors.NotEnoughYield.selector);
        rewardsManager.reward(assets[0], 1000e6);
    }

    function test_rewardYield_noYield_reverts() public {
        vm.startPrank(strategist.addr);

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        vm.expectRevert(IRewardsManagerErrors.NotEnoughYield.selector);
        rewardsManager.reward(assets[0], 0);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertEq(treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore, 0, "Accrued amount should be 0");
    }

    function test_rewardYield_aaveYield_succeeds(uint256 accrued) public {
        accrued = bound(accrued, 1, INITIAL_BALANCE / 2);

        vm.startPrank(strategist.addr);

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        config.tokens.aUsdc.transfer(address(rewardsManager.vault()), accrued);
        config.tokens.aUsdt.transfer(address(rewardsManager.vault()), accrued);

        assertApproxEqAbs(
            rewardsManager.getAccruedYield(assets).convertDecimalsDown(
                vaultManager.vault().decimals(), ERC20(assets[0]).decimals()
            ),
            accrued * 2,
            2,
            "Accrued amount does not match"
        );

        // getAccruedYield() can be ~2 less than accrued * 2 due to rounding
        // so we reward 2 * accrued - 2
        uint256 yieldAmount = 2 * accrued - 2;
        rewardsManager.reward(assets[0], yieldAmount);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertApproxEqAbs(
            treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore, yieldAmount, 2, "Accrued amount does not match"
        );

        uint256 totalAssets = vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdc)), address(config.tokens.usdc)
        );

        totalAssets += vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdt)), address(config.tokens.usdt)
        );

        // Due to rounding, we allow for a 0.01% difference
        // This is because there can be small left over yield (eg. 0.00000001)
        assertApproxEqRel(
            totalAssets.convertDecimalsDown(ERC20(assets[0]).decimals(), vaultManager.vault().decimals()),
            INITIAL_SHARES,
            0.0001e18, // Allow for 0.01% difference
            "The value of the vault should be approximately equal to the number of shares"
        );
    }

    function test_rewardYield_partialYield_succeeds(uint256 accrued) public {
        accrued = bound(accrued, 1, INITIAL_BALANCE / 2);

        vm.startPrank(strategist.addr);

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        config.tokens.aUsdc.transfer(address(rewardsManager.vault()), accrued);
        config.tokens.aUsdt.transfer(address(rewardsManager.vault()), accrued);

        assertApproxEqAbs(
            rewardsManager.getAccruedYield(assets).convertDecimalsDown(
                vaultManager.vault().decimals(), ERC20(assets[0]).decimals()
            ),
            accrued * 2,
            2,
            "Accrued amount does not match"
        );

        // Only reward 80% of the accrued yield
        uint256 yieldAmount = accrued * 2 * 8 / 10;
        rewardsManager.reward(assets[0], yieldAmount);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertApproxEqAbs(
            treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore, yieldAmount, 2, "Accrued amount does not match"
        );

        uint256 totalAssets = vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdc)), address(config.tokens.usdc)
        );

        totalAssets += vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdt)), address(config.tokens.usdt)
        );

        uint256 leftOverYield = accrued * 2 * 2 / 10;
        uint256 leftOverYieldInVaultPrecision =
            leftOverYield.convertDecimalsDown(ERC20(assets[0]).decimals(), vaultManager.vault().decimals());

        // Due to rounding, we allow for a 0.01% difference
        // This is because there can be small left over yield (eg. 0.00000001)
        // We also need to account for the remaining yield that was not rewarded
        assertApproxEqRel(
            totalAssets.convertDecimalsDown(ERC20(assets[0]).decimals(), vaultManager.vault().decimals()),
            INITIAL_SHARES + leftOverYieldInVaultPrecision,
            0.0001e18, // Allow for 0.01% difference
            "The value of the vault should be approximately equal to the number of shares"
        );
    }

    function test_rewardYield_underPeg_reverts() public {
        vm.startPrank(strategist.addr);

        // Set oracle price to 0.95 (under peg)
        uint256 underPegPrice = 99e6; // 0.95 in 8 decimals
        mockOracle.updatePriceAndDecimals(int256(underPegPrice), 8);

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        // Transfer some aTokens to simulate yield
        uint256 accrued = 1000e6; // 1000 USDC
        config.tokens.aUsdc.transfer(address(rewardsManager.vault()), accrued);
        config.tokens.aUsdt.transfer(address(rewardsManager.vault()), accrued);

        // The accrued yield should be 0 because the price is under peg
        uint256 accruedYield = rewardsManager.getAccruedYield(assets);
        assertEq(accruedYield, 0, "Accrued yield should be 0");

        // Execute reward should revert
        vm.expectRevert(IRewardsManagerErrors.NotEnoughYield.selector);
        rewardsManager.reward(assets[0], 0);
    }

    function test_basic_getAccruedYield_succeeds() public {
        StrategyConfig[] memory strategies = rewardsManager.getAllStrategies(address(config.tokens.usdc));
        assertGt(strategies.length, 0, "Should have at least one strategy for USDC");

        // Transfer some aUSDC to the vault to simulate yield
        vm.startPrank(strategist.addr);
        uint256 accrued = 1000e6;
        config.tokens.aUsdc.transfer(address(rewardsManager.vault()), accrued);
        console2.log("Transferring aUSDC to vault");

        // Call getAccruedYield - should not revert
        uint256 yield = rewardsManager.getAccruedYield(assets);
        assertGt(yield, 0, "Should have accrued some yield");
    }

    // ------------- Internal Helpers -------------

    function _getAssetsInStrategy(address asset, address strategy) public view returns (uint256) {
        (
            StrategyCategory category,
            ERC20 baseCollateral,
            ERC20 receiptToken,
            AggregatorV3Interface oracle,
            address depositContract,
            address withdrawContract,
            uint256 heartbeat
        ) = vaultManager.assetToStrategy(asset, strategy);

        StrategyConfig memory config = StrategyConfig({
            category: category,
            baseCollateral: baseCollateral,
            receiptToken: receiptToken,
            oracle: oracle,
            depositContract: depositContract,
            withdrawContract: withdrawContract,
            heartbeat: heartbeat
        });

        return StrategyLib.getAssets(config, address(vaultManager.vault()));
    }

    function _scheduleAndExecuteAdminAction(address target, bytes memory data) internal {
        vm.startPrank(config.users.admin);
        config.levelContracts.adminTimelock.schedule(target, 0, data, bytes32(0), 0, 3 days);

        vm.warp(block.timestamp + 3 days);

        config.levelContracts.adminTimelock.execute(target, 0, data, bytes32(0), 0);
        vm.stopPrank();
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

    // Test cases to add:
    // - Test when morpho yield accrues
}
