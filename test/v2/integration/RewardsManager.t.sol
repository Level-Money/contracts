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

contract RewardsManagerMainnetTests is Utils, Configurable {
    using SafeTransferLib for ERC20;
    using VaultLib for BoringVault;
    using MathLib for uint256;

    Vm.Wallet private deployer;
    Vm.Wallet private strategist;

    RewardsManager public rewardsManager;
    VaultManager public vaultManager;

    uint256 public constant INITIAL_BALANCE = 100_000_000e6;
    uint256 public constant INITIAL_SHARES = 200_000_000e18;

    address[] public assets;

    function setUp() public {
        forkMainnet(22134385);

        deployer = vm.createWallet("deployer");
        strategist = vm.createWallet("strategist");

        DeployLevel deployScript = new DeployLevel();

        // Deploy

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        // Setup strategist
        address[] memory targets = new address[](2);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.rolesAuthority);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, STRATEGIST_ROLE, true);
        payloads[1] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, REWARDER_ROLE, true);

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

    function test_rewardYield_noYield_reverts() public {
        vm.startPrank(strategist.addr);

        uint256 treasuryUsdcBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        vm.expectRevert(IRewardsManagerErrors.NotEnoughYield.selector);
        rewardsManager.reward(assets);

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

        rewardsManager.reward(assets);

        uint256 treasuryUsdcBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

        assertApproxEqAbs(
            treasuryUsdcBalanceAfter - treasuryUsdcBalanceBefore, 2 * accrued, 2, "Accrued amount does not match"
        );

        uint256 totalAssets = vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdc)), address(config.tokens.usdc)
        );

        totalAssets += vaultManager.vault()._getTotalAssets(
            rewardsManager.getAllStrategies(address(config.tokens.usdt)), address(config.tokens.usdt)
        );

        assertApproxEqAbs(
            totalAssets.convertDecimalsDown(ERC20(assets[0]).decimals(), vaultManager.vault().decimals()),
            INITIAL_SHARES,
            1,
            "The value of the vault should be approximately equal to the number of shares"
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

    function _printBalance(address asset, address vault) internal {
        console2.log(vm.getLabel(asset), ERC20(asset).balanceOf(vault));
    }

    // Test cases to add:
    // - Test when morpho yield accrues
    // - Test that you can't reward more than accrued
}
