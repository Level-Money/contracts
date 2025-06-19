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
import {MockERC4626} from "@level/test/v2/mocks/MockERC4626.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {ILevelMintingV2Structs} from "@level/src/v2/interfaces/level/ILevelMintingV2.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";
import {CappedOneDollarOracle} from "@level/src/v2/oracles/CappedOneDollarOracle.sol";
import {ISuperstateToken} from "@level/src/v2/interfaces/superstate/ISuperstateToken.sol";
import {IAllowListV2} from "@level/src/v2/interfaces/superstate/IAllowListV2.sol";

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

    address public constant USTB_CHAINLINK_FEED = 0xE4fA682f94610cCd170680cc3B045d77D9E528a8;

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
        _mockChainlinkCall(address(config.oracles.ustb), 105e5); // 10.5 USD per USTB
        _mockChainlinkCall(address(config.oracles.mNav), 1e8); // 1 USD per wrappedM

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

    function test_tooHighYieldAmount_reverts(uint256 yieldAmount) public {
        vm.startPrank(strategist.addr);

        // Transfer some aTokens to simulate yield
        uint256 accrued = 1000e6; // 1000 USDC
        config.tokens.aUsdc.transfer(address(rewardsManager.vault()), accrued);
        config.tokens.aUsdt.transfer(address(rewardsManager.vault()), accrued);

        // Get the actual accrued yield in the redemption asset's decimals
        uint256 actualAccruedYield = rewardsManager.getAccruedYield(assets).convertDecimalsDown(
            vaultManager.vault().decimals(), ERC20(assets[0]).decimals()
        );

        // Bound the fuzzed amount to be greater than the actual accrued yield
        yieldAmount = bound(yieldAmount, actualAccruedYield + 1, type(uint256).max);

        vm.expectRevert(IRewardsManagerErrors.NotEnoughYield.selector);
        rewardsManager.reward(assets[0], yieldAmount);
    }

    function test_appropriateYieldAmount_succeeds(uint256 yieldAmount) public {
        vm.startPrank(strategist.addr);

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        // Transfer some aTokens to simulate yield
        uint256 accrued = 1000e6; // 1000 USDC
        config.tokens.aUsdc.transfer(address(rewardsManager.vault()), accrued);
        config.tokens.aUsdt.transfer(address(rewardsManager.vault()), accrued);

        // Get the actual accrued yield in the redemption asset's decimals
        uint256 actualAccruedYield = rewardsManager.getAccruedYield(assets).convertDecimalsDown(
            vaultManager.vault().decimals(), ERC20(assets[0]).decimals()
        );

        // Bound the fuzzed amount to be less than the actual accrued yield
        yieldAmount = bound(yieldAmount, 0, actualAccruedYield - 1);

        rewardsManager.reward(assets[0], yieldAmount);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertApproxEqAbs(
            treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore, yieldAmount, 2, "Accrued amount does not match"
        );
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

    function test_rewardYield_morphoYield_succeeds2(uint256 deposit) public {
        deposit = bound(deposit, 2000, 500000e6);
        deal(address(config.tokens.usdc), address(strategist.addr), deposit);

        vm.startPrank(config.users.admin);
        lvlUSD _lvlUSD = lvlUSD(address(config.tokens.lvlUsd));
        _lvlUSD.setMinter(address(config.levelContracts.levelMintingV2));
        vm.stopPrank();
        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        // Create a mock vault to simulate Morpho and manipulate yield
        MockERC4626 mockUsdcERC4626 = new MockERC4626(IERC20(address(config.tokens.usdc)));
        IERC4626Oracle mockMorphoOracle =
            IERC4626Oracle(config.levelContracts.erc4626OracleFactory.create(mockUsdcERC4626));
        MockOracle mockOracle = new MockOracle(1e8, 8);

        // Seed mock vault with USDC
        mockUsdcERC4626.setConvertToAssetsOutput(10 ** mockUsdcERC4626.decimals());

        // Set Morpho only as a default strategy
        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = address(mockUsdcERC4626);

        StrategyConfig[] memory strategies = new StrategyConfig[](1);
        strategies[0] = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(mockUsdcERC4626)),
            oracle: mockMorphoOracle,
            depositContract: address(mockUsdcERC4626),
            withdrawContract: address(mockUsdcERC4626),
            heartbeat: 1 days
        });

        address[] memory targets = new address[](4);
        targets[0] = address(config.levelContracts.vaultManager);
        targets[1] = address(config.levelContracts.vaultManager);
        targets[2] = address(config.levelContracts.rewardsManager);
        targets[3] = address(config.levelContracts.levelMintingV2);

        bytes[] memory payloads = new bytes[](4);
        payloads[0] = abi.encodeWithSelector(
            VaultManager.addAssetStrategy.selector, address(config.tokens.usdc), address(mockUsdcERC4626), strategies[0]
        );
        payloads[1] = abi.encodeWithSignature(
            "setDefaultStrategies(address,address[])", address(config.tokens.usdc), defaultStrategies
        );
        payloads[2] =
            abi.encodeWithSelector(RewardsManager.setAllStrategies.selector, address(config.tokens.usdc), strategies);
        payloads[3] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdc), address(mockOracle), false
        );
        _scheduleAndExecuteAdminActionBatch(
            address(config.users.admin), address(config.levelContracts.adminTimelock), targets, payloads
        );
        _mockChainlinkCall(address(config.oracles.ustb), 105e5); // 10.5 USD per USTB

        vm.startPrank(strategist.addr);

        // Approve USDC
        ERC20(address(config.tokens.usdc)).safeApprove(address(config.levelContracts.boringVault), type(uint256).max);

        // Use levelMinting to mint
        config.levelContracts.levelMintingV2.mint(
            ILevelMintingV2Structs.Order({
                collateral_asset: address(config.tokens.usdc),
                collateral_amount: deposit,
                min_lvlusd_amount: 0,
                beneficiary: address(strategist.addr)
            })
        );

        // Check if assets are deposited in our mock vault
        assertEq(
            mockUsdcERC4626.balanceOf(address(vaultManager.vault())), deposit, "Assets not deposited in mock vault"
        );

        // Simulate yield by increasing the value of vault shares
        uint256 yieldPrice = 1.1e6; // 10% yield
        mockUsdcERC4626.setConvertToAssetsOutput(yieldPrice);

        // Get the accrued yield in the redemption asset's decimals
        uint256 actualAccruedYield = rewardsManager.getAccruedYield(assets).convertDecimalsDown(
            vaultManager.vault().decimals(), ERC20(assets[0]).decimals()
        );

        // Calculate expected yield (10% of deposit)
        uint256 expectedYield = deposit * 10 / 100;
        assertApproxEqAbs(actualAccruedYield, expectedYield, 2, "Accrued yield does not match expected yield");

        // Reward the yield
        rewardsManager.reward(assets[0], actualAccruedYield);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertApproxEqAbs(
            treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore,
            actualAccruedYield,
            2,
            "Rewarded amount does not match"
        );

        // Verify total assets are correct after reward
        uint256 totalAssets = vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdc)), address(config.tokens.usdc)
        );

        totalAssets += vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdt)), address(config.tokens.usdt)
        );

        // Due to rounding, we allow for a 0.01% difference
        assertApproxEqRel(totalAssets, 2 * INITIAL_BALANCE + deposit, 0.0001e18, "Total assets do not match");
    }

    function test_customMNavOracle_succeeds() public {
        // wrappedM oracle should return 1 USD
        CappedOneDollarOracle mNavOracle = new CappedOneDollarOracle(address(config.oracles.mNav));

        // Get latest price from the oracle
        (, int256 price,,,) = mNavOracle.latestRoundData();
        assertEq(price, 1e8, "Price should be 1 USD");

        _mockChainlinkCall(address(config.oracles.mNav), 105e6); // 1.05 USD per M

        // Get latest price from the oracle
        (, price,,,) = mNavOracle.latestRoundData();
        assertEq(price, 1e8, "Price should be 1 USD");

        _mockChainlinkCall(address(config.oracles.mNav), 99e6); // 0.99 USD per M

        // Get latest price from the oracle
        (, price,,,) = mNavOracle.latestRoundData();
        assertEq(price, 99e6, "Price should be 0.99 USD");
    }

    function test_sparkYield_succeeds(uint256 deposit) public {
        deposit = bound(deposit, 1000, 1_000_000e6);

        // Deposit some USDC into the spark vault
        vm.prank(strategist.addr);
        vaultManager.deposit(address(config.tokens.usdc), address(config.sparkVaults.sUsdc.vault), deposit);

        // Preview deposit
        uint256 expectedShares = config.sparkVaults.sUsdc.vault.convertToShares(deposit);

        // Ensure we have the expected shares
        assertEq(config.sparkVaults.sUsdc.vault.balanceOf(address(vaultManager.vault())), expectedShares);

        // Get the accrued yield in the redemption asset's decimals
        uint256 accruedYield = rewardsManager.getAccruedYield(assets);

        // Accrued yield should be 0 at this point
        assertApproxEqAbs(accruedYield, 0, 1, "Accrued yield should be 0");

        // Travel to the future to get yield
        vm.warp(block.timestamp + 10 days);

        // Avoid stale prices
        _mockChainlinkCall(address(config.oracles.ustb), 105e5); // 10.5 USD per USTB
        _mockChainlinkCall(address(config.oracles.mNav), 1e8); // 1 USD per wrappedM

        // Get the accrued yield in the redemption asset's decimals
        accruedYield = rewardsManager.getAccruedYield(assets);

        // Yield should be non-zero
        assertGt(accruedYield, 0, "Accrued yield should be non-zero");

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        // Fuzz a yield amount between 0 and the accrued yield
        uint256 yieldAmount;
        yieldAmount = bound(yieldAmount, 1, accruedYield);

        // Reward the yield
        vm.prank(strategist.addr);
        rewardsManager.reward(assets[0], yieldAmount);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertApproxEqAbs(
            treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore, yieldAmount, 2, "Rewarded amount does not match"
        );
    }

    function test_ustbYield_succeeds(uint256 deposit) public {
        deposit = bound(deposit, 1000, 1_000_000e6);

        _mockChainlinkCall(USTB_CHAINLINK_FEED, 105e5); // 10.5 USD per USTB

        (uint256 superstateTokenOutAmount,,) = ISuperstateToken(address(config.tokens.ustb)).calculateSuperstateTokenOut(
            deposit, address(config.tokens.usdc)
        );

        // Superstate Allowlist V2 on Mainnet
        IAllowListV2 allowList = IAllowListV2(0x02f1fA8B196d21c7b733EB2700B825611d8A38E5);
        address[] memory addresses = new address[](1);
        addresses[0] = address(config.levelContracts.boringVault);

        vm.prank(allowList.owner());
        allowList.setProtocolAddressPermissions(addresses, "USTB", true);

        // Deposit some USDC into the ustb vault
        vm.prank(strategist.addr);
        vaultManager.deposit(address(config.tokens.usdc), address(config.tokens.ustb), deposit);

        // Ensure we have the expected USTB
        assertEq(config.tokens.ustb.balanceOf(address(vaultManager.vault())), superstateTokenOutAmount);

        // Overtime, the USTB NAV will increase, and we will get yield
        _mockChainlinkCall(address(config.oracles.ustb), 107e5); // 10.7 USD per USTB

        // Get the accrued yield in the redemption asset's decimals
        uint256 accruedYield = rewardsManager.getAccruedYield(assets);

        // Yield should be non-zero
        assertGt(accruedYield, 0, "Accrued yield should be non-zero");

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        // Fuzz a yield amount between 0 and the accrued yield
        uint256 yieldAmount;
        yieldAmount = bound(yieldAmount, 1, accruedYield);

        // Reward the yield
        vm.prank(strategist.addr);
        rewardsManager.reward(assets[0], yieldAmount);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertApproxEqAbs(
            treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore, yieldAmount, 2, "Rewarded amount does not match"
        );
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

    // Need to mock chainlink call for ustb
    // because vm.warp() makes it return stale prices
    function _mockChainlinkCall(address chainLinkFeed, int256 price) internal {
        AggregatorV3Interface chainlink = AggregatorV3Interface(chainLinkFeed);

        uint80 roundId = 1;
        uint256 startedAt = block.timestamp;
        uint256 updatedAt = block.timestamp;
        uint80 answeredInRound = 1;

        vm.mockCall(
            address(chainlink),
            abi.encodeWithSelector(chainlink.latestRoundData.selector),
            abi.encode(roundId, price, startedAt, updatedAt, answeredInRound)
        );
    }

    function _printBalance(address asset, address vault) internal {
        console2.log(vm.getLabel(asset), ERC20(asset).balanceOf(vault));
    }
}
