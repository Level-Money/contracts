// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test, Vm} from "forge-std/Test.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {StrategyConfig, StrategyLib, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {LevelReserveLens} from "@level/src/v2/lens/LevelReserveLens.sol";
import {UpgradeLevelReserveLens} from "@level/script/v2/lens/UpgradeLevelReserveLens.s.sol";

contract RewardsManagerMainnetTests is Utils, Configurable {
    using SafeTransferLib for ERC20;
    using MathLib for uint256;

    Vm.Wallet private deployer;

    RewardsManager public rewardsManager;
    LevelReserveLens public lens;

    uint256 public constant INITIAL_BALANCE = 1000e6;

    function setUp() public {
        forkMainnet(22276630);

        deployer = vm.createWallet("deployer");

        DeployLevel deployScript = new DeployLevel();

        // Deploy

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        rewardsManager = config.levelContracts.rewardsManager;
        lens = config.levelContracts.levelReserveLens;

        // Upgrade level reserve lens
        UpgradeLevelReserveLens upgradeScript = new UpgradeLevelReserveLens();

        vm.prank(deployer.addr);
        upgradeScript.setUp_(1, deployer.privateKey);

        upgradeScript.run();
    }

    function test__getReservesSuccedsWithBaseCollateral() public {
        uint256 usdcReservesBeforeDeal = lens.getReserves(address(config.tokens.usdc));
        uint256 usdtReservesBeforeDeal = lens.getReserves(address(config.tokens.usdt));

        deal(address(config.tokens.usdc), address(config.levelContracts.boringVault), INITIAL_BALANCE);
        deal(address(config.tokens.usdt), address(config.levelContracts.boringVault), INITIAL_BALANCE);

        uint256 usdcReservesAfterDeal = lens.getReserves(address(config.tokens.usdc));
        uint256 usdtReservesAfterDeal = lens.getReserves(address(config.tokens.usdt));

        assertEq(
            usdcReservesAfterDeal,
            usdcReservesBeforeDeal
                + INITIAL_BALANCE.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals()),
            "USDC reserves do not match"
        );
        assertEq(
            usdtReservesAfterDeal,
            usdtReservesBeforeDeal
                + INITIAL_BALANCE.convertDecimalsDown(config.tokens.usdt.decimals(), config.tokens.lvlUsd.decimals()),
            "USDT reserves do not match"
        );
    }

    function test__getReserves_succeedsWithAaveTokens() public {
        uint256 usdcReservesBeforeDeal = lens.getReserves(address(config.tokens.usdc));
        uint256 usdtReservesBeforeDeal = lens.getReserves(address(config.tokens.usdt));

        vm.startPrank(deployer.addr);

        deal(address(config.tokens.usdc), address(deployer.addr), INITIAL_BALANCE);
        deal(address(config.tokens.usdt), address(deployer.addr), INITIAL_BALANCE);

        // Get some aUsdc and aUsdt
        ERC20(config.tokens.usdc).safeApprove(address(config.periphery.aaveV3), INITIAL_BALANCE);
        ERC20(config.tokens.usdt).safeApprove(address(config.periphery.aaveV3), INITIAL_BALANCE);

        config.periphery.aaveV3.supply(address(config.tokens.usdc), INITIAL_BALANCE, deployer.addr, 0);
        config.periphery.aaveV3.supply(address(config.tokens.usdt), INITIAL_BALANCE, deployer.addr, 0);

        config.tokens.aUsdc.transfer(address(config.levelContracts.boringVault), INITIAL_BALANCE);
        config.tokens.aUsdt.transfer(address(config.levelContracts.boringVault), INITIAL_BALANCE);
        vm.stopPrank();

        uint256 usdcReservesAfterDeal = lens.getReserves(address(config.tokens.usdc));
        uint256 usdtReservesAfterDeal = lens.getReserves(address(config.tokens.usdt));

        assertEq(
            usdcReservesAfterDeal,
            usdcReservesBeforeDeal
                + INITIAL_BALANCE.convertDecimalsDown(config.tokens.aUsdc.decimals(), config.tokens.lvlUsd.decimals()),
            "USDC reserves do not match"
        );
        assertEq(
            usdtReservesAfterDeal,
            usdtReservesBeforeDeal
                + INITIAL_BALANCE.convertDecimalsDown(config.tokens.aUsdt.decimals(), config.tokens.lvlUsd.decimals()),
            "USDT reserves do not match"
        );
    }

    function test__getReserves_succedsWithMorphoTokens() public {
        uint256 steakhouseUsdcShares = 1000000e18;
        uint256 usdcReservesBeforeDeal = lens.getReserves(address(config.tokens.usdc));

        deal(
            address(config.morphoVaults.steakhouseUsdc.vault),
            address(config.levelContracts.boringVault),
            steakhouseUsdcShares
        );

        uint256 steakhouseUsdcAssets = config.morphoVaults.steakhouseUsdc.vault.convertToAssets(steakhouseUsdcShares);

        uint256 usdcReservesAfterDeal = lens.getReserves(address(config.tokens.usdc));

        assertApproxEqRel(
            usdcReservesAfterDeal,
            usdcReservesBeforeDeal
                + steakhouseUsdcAssets.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals()),
            0.00000001e18,
            "USDC reserves do not match"
        );
    }
}
