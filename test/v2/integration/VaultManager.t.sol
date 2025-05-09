// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test, Vm} from "forge-std/Test.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {StrategyConfig, StrategyLib, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";

contract VaultManagerMainnetTests is Utils, Configurable {
    using SafeTransferLib for ERC20;

    Vm.Wallet private deployer;
    Vm.Wallet private strategist;

    VaultManager public vaultManager;

    uint256 public constant INITIAL_BALANCE = 100_000_000e6;
    uint256 public constant INITIAL_SHARES = 200_000_000e18;

    StrategyConfig[] public usdcStrategies;
    StrategyConfig[] public usdtStrategies;

    StrategyConfig public steakhouseUsdcConfig;
    StrategyConfig public steakhouseUsdtConfig;
    StrategyConfig public re7UsdcConfig;
    StrategyConfig public steakhouseUsdtLiteConfig;

    function setUp() public {
        forkMainnet(22305203);

        deployer = vm.createWallet("deployer");
        strategist = vm.createWallet("strategist");

        DeployLevel deployScript = new DeployLevel();

        // Deploy

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        // Setup strategist
        vm.prank(config.users.admin);
        _setupMorphoVaultsForTests();

        address[] memory targets = new address[](2);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.rolesAuthority);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, STRATEGIST_ROLE, true);
        payloads[1] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, REWARDER_ROLE, true);

        _scheduleAndExecuteAdminActionBatch(
            address(config.users.admin), address(config.levelContracts.adminTimelock), targets, payloads
        );

        deal(address(config.tokens.usdc), address(config.levelContracts.boringVault), INITIAL_BALANCE);
        deal(address(config.tokens.usdt), address(config.levelContracts.boringVault), INITIAL_BALANCE);

        deal(address(config.levelContracts.boringVault), address(config.levelContracts.boringVault), INITIAL_SHARES);

        vaultManager = config.levelContracts.vaultManager;

        address[] memory usdcStrategyAddresses = vaultManager.getDefaultStrategies(address(config.tokens.usdc));
        address[] memory usdtStrategyAddresses = vaultManager.getDefaultStrategies(address(config.tokens.usdt));

        usdcStrategies = new StrategyConfig[](usdcStrategyAddresses.length);
        usdtStrategies = new StrategyConfig[](usdtStrategyAddresses.length);

        for (uint256 i = 0; i < usdcStrategyAddresses.length; i++) {
            (
                StrategyCategory category,
                ERC20 baseCollateral,
                ERC20 receiptToken,
                AggregatorV3Interface oracle,
                address depositContract,
                address withdrawContract,
                uint256 heartbeat
            ) = vaultManager.assetToStrategy(address(config.tokens.usdc), usdcStrategyAddresses[i]);

            usdcStrategies[i] = StrategyConfig({
                category: category,
                baseCollateral: baseCollateral,
                receiptToken: receiptToken,
                oracle: oracle,
                depositContract: depositContract,
                withdrawContract: withdrawContract,
                heartbeat: heartbeat
            });
        }

        for (uint256 i = 0; i < usdtStrategyAddresses.length; i++) {
            (
                StrategyCategory category,
                ERC20 baseCollateral,
                ERC20 receiptToken,
                AggregatorV3Interface oracle,
                address depositContract,
                address withdrawContract,
                uint256 heartbeat
            ) = vaultManager.assetToStrategy(address(config.tokens.usdt), usdtStrategyAddresses[i]);

            usdtStrategies[i] = StrategyConfig({
                category: category,
                baseCollateral: baseCollateral,
                receiptToken: receiptToken,
                oracle: oracle,
                depositContract: depositContract,
                withdrawContract: withdrawContract,
                heartbeat: heartbeat
            });
        }
    }

    function _setupMorphoVaultsForTests() internal {
        //--------------- Add test Morpho vaults as strategies
        if (address(config.morphoVaults.steakhouseUsdt.vault) == address(0)) {
            revert("Steakhouse USDT vaults not deployed");
        }

        if (address(config.morphoVaults.re7Usdc.vault) == address(0)) {
            revert("Re7 USDC vaults not deployed");
        }

        if (address(config.morphoVaults.steakhouseUsdtLite.vault) == address(0)) {
            revert("Steakhouse USDT Lite vaults not deployed");
        }

        if (address(config.morphoVaults.re7Usdc.oracle) == address(0)) {
            config.morphoVaults.re7Usdc.oracle = deployERC4626Oracle(config.morphoVaults.re7Usdc.vault, 4 hours);
        }

        if (address(config.morphoVaults.steakhouseUsdt.oracle) == address(0)) {
            config.morphoVaults.steakhouseUsdt.oracle =
                deployERC4626Oracle(config.morphoVaults.steakhouseUsdt.vault, 4 hours);
        }

        if (address(config.morphoVaults.steakhouseUsdtLite.oracle) == address(0)) {
            config.morphoVaults.steakhouseUsdtLite.oracle =
                deployERC4626Oracle(config.morphoVaults.steakhouseUsdtLite.vault, 4 hours);
        }

        //--------------- Add test Morpho vaults as strategies
        steakhouseUsdcConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(config.morphoVaults.steakhouseUsdc.vault)),
            oracle: config.morphoVaults.steakhouseUsdc.oracle,
            depositContract: address(config.morphoVaults.steakhouseUsdc.vault),
            withdrawContract: address(config.morphoVaults.steakhouseUsdc.vault),
            heartbeat: 1 days
        });

        steakhouseUsdtConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdt,
            receiptToken: ERC20(address(config.morphoVaults.steakhouseUsdt.vault)),
            oracle: config.morphoVaults.steakhouseUsdt.oracle,
            depositContract: address(config.morphoVaults.steakhouseUsdt.vault),
            withdrawContract: address(config.morphoVaults.steakhouseUsdt.vault),
            heartbeat: 1 days
        });

        re7UsdcConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdc,
            receiptToken: ERC20(address(config.morphoVaults.re7Usdc.vault)),
            oracle: config.morphoVaults.re7Usdc.oracle,
            depositContract: address(config.morphoVaults.re7Usdc.vault),
            withdrawContract: address(config.morphoVaults.re7Usdc.vault),
            heartbeat: 1 days
        });

        steakhouseUsdtLiteConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdt,
            receiptToken: ERC20(address(config.morphoVaults.steakhouseUsdtLite.vault)),
            oracle: config.morphoVaults.steakhouseUsdtLite.oracle,
            depositContract: address(config.morphoVaults.steakhouseUsdtLite.vault),
            withdrawContract: address(config.morphoVaults.steakhouseUsdtLite.vault),
            heartbeat: 1 days
        });

        address[] memory usdcDefaultStrategies = new address[](3);
        usdcDefaultStrategies[0] = address(config.periphery.aaveV3);
        usdcDefaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        usdcDefaultStrategies[2] = address(config.morphoVaults.re7Usdc.vault);

        address[] memory usdtDefaultStrategies = new address[](3);
        usdtDefaultStrategies[0] = address(config.periphery.aaveV3);
        usdtDefaultStrategies[1] = address(config.morphoVaults.steakhouseUsdt.vault);
        usdtDefaultStrategies[2] = address(config.morphoVaults.steakhouseUsdtLite.vault);

        address[] memory targets = new address[](5);
        targets[0] = address(config.levelContracts.vaultManager);
        targets[1] = address(config.levelContracts.vaultManager);
        targets[2] = address(config.levelContracts.vaultManager);
        targets[3] = address(config.levelContracts.vaultManager);
        targets[4] = address(config.levelContracts.vaultManager);

        bytes[] memory payloads = new bytes[](5);
        payloads[0] = abi.encodeWithSelector(
            VaultManager.addAssetStrategy.selector,
            address(config.tokens.usdc),
            address(config.morphoVaults.re7Usdc.vault),
            re7UsdcConfig
        );
        payloads[1] = abi.encodeWithSelector(
            VaultManager.addAssetStrategy.selector,
            address(config.tokens.usdt),
            address(config.morphoVaults.steakhouseUsdt.vault),
            steakhouseUsdtConfig
        );
        payloads[2] = abi.encodeWithSelector(
            VaultManager.addAssetStrategy.selector,
            address(config.tokens.usdt),
            address(config.morphoVaults.steakhouseUsdtLite.vault),
            steakhouseUsdtLiteConfig
        );
        payloads[3] = abi.encodeWithSelector(
            VaultManager.setDefaultStrategies.selector, address(config.tokens.usdc), usdcDefaultStrategies
        );
        payloads[4] = abi.encodeWithSelector(
            VaultManager.setDefaultStrategies.selector, address(config.tokens.usdt), usdtDefaultStrategies
        );

        _scheduleAndExecuteAdminActionBatch(
            address(config.users.admin), address(config.levelContracts.adminTimelock), targets, payloads
        );
    }

    function deployERC4626Oracle(IERC4626 vault, uint256 delay) public returns (IERC4626Oracle) {
        if (address(config.levelContracts.erc4626OracleFactory) == address(0)) {
            revert("ERC4626OracleFactory must be deployed first");
        }

        IERC4626Oracle _erc4626Oracle = IERC4626Oracle(config.levelContracts.erc4626OracleFactory.create(vault));
        vm.label(address(_erc4626Oracle), string.concat(vault.name(), " Oracle"));

        return _erc4626Oracle;
    }

    function test_depositDefault_usdc_aaveOnly_succeeds(uint256 deposit) public {
        deposit = bound(deposit, 1, INITIAL_BALANCE);

        // Set Aave only as a default strategy
        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = address(config.periphery.aaveV3);

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature(
                "setDefaultStrategies(address,address[])", address(config.tokens.usdc), defaultStrategies
            )
        );

        vm.startPrank(strategist.addr);

        vaultManager.depositDefault(address(config.tokens.usdc), deposit);

        assertEq(
            config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_SHARES,
            "Number of shares must not change"
        );

        assertApproxEqAbs(
            config.tokens.usdc.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit,
            1,
            "Wrong amount of usdc"
        );

        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)),
            deposit,
            1,
            "Wrong amount of aUsdc"
        );
    }

    function test_depositDefault_usdt_aaveOnly_succeeds(uint256 deposit) public {
        deposit = bound(deposit, 1, INITIAL_BALANCE);

        // Set Aave only as a default strategy
        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = address(config.periphery.aaveV3);

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature(
                "setDefaultStrategies(address,address[])", address(config.tokens.usdt), defaultStrategies
            )
        );

        vm.startPrank(strategist.addr);

        vaultManager.depositDefault(address(config.tokens.usdt), deposit);

        assertEq(
            config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_SHARES,
            "Number of shares must not change"
        );
        assertApproxEqAbs(
            config.tokens.usdt.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit,
            1,
            "Wrong amount of usdt"
        );

        // Though Aave claims that their receipt token is 1:1 with the underlying asset, it is often off by one.
        assertApproxEqAbs(
            config.tokens.aUsdt.balanceOf(address(config.levelContracts.boringVault)),
            deposit,
            1,
            "Wrong amount of aUsdt"
        );
    }

    function test_withdrawDefault_usdc_aaveOnly_succeeds(uint256 deposit, uint256 withdrawal) public {
        deposit = bound(deposit, 2, INITIAL_BALANCE);
        withdrawal = bound(withdrawal, 1, deposit - 1);
        // Set Aave only as a default strategy
        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = address(config.periphery.aaveV3);

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature(
                "setDefaultStrategies(address,address[])", address(config.tokens.usdc), defaultStrategies
            )
        );

        vm.startPrank(strategist.addr);

        vaultManager.depositDefault(address(config.tokens.usdc), deposit);
        vaultManager.withdrawDefault(address(config.tokens.usdc), withdrawal);

        assertEq(
            config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_SHARES,
            "Number of shares must not change"
        );
        assertApproxEqAbs(
            config.tokens.usdc.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit + withdrawal,
            1,
            "Wrong amount of usdc"
        );

        assertApproxEqAbs(
            config.tokens.aUsdc.balanceOf(address(config.levelContracts.boringVault)),
            deposit - withdrawal,
            1,
            "Wrong amount of aUsdc"
        );
    }

    function test_withdrawDefault_usdt_aaveOnly_succeeds(uint256 deposit, uint256 withdrawal) public {
        deposit = bound(deposit, 2, INITIAL_BALANCE);
        withdrawal = bound(withdrawal, 1, deposit - 1);
        // Set Aave only as a default strategy
        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = address(config.periphery.aaveV3);

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature(
                "setDefaultStrategies(address,address[])", address(config.tokens.usdt), defaultStrategies
            )
        );

        vm.startPrank(strategist.addr);

        vaultManager.depositDefault(address(config.tokens.usdt), deposit);
        vaultManager.withdrawDefault(address(config.tokens.usdt), withdrawal);

        assertEq(
            config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_SHARES,
            "Number of shares must not change"
        );
        assertApproxEqAbs(
            config.tokens.usdt.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit + withdrawal,
            1,
            "Wrong amount of usdt"
        );

        assertApproxEqAbs(
            config.tokens.aUsdt.balanceOf(address(config.levelContracts.boringVault)),
            deposit - withdrawal,
            1,
            "Wrong amount of aUsdt"
        );
    }

    // Test on both MetaMorpho and MetaMorphoV1_1
    function test_depositDefault_usdc_morphoOnly_succeeds(uint256 deposit) public {
        _depositDefault_morphoOnly(deposit, config.tokens.usdc, address(config.morphoVaults.steakhouseUsdc.vault));
    }

    function test_depositDefault_usdc_morphoV1_1_succeeds(uint256 deposit) public {
        _depositDefault_morphoOnly(deposit, config.tokens.usdc, address(config.morphoVaults.re7Usdc.vault));
    }

    function test_depositDefault_usdt_morphoOnly_succeeds(uint256 deposit) public {
        _depositDefault_morphoOnly(deposit, config.tokens.usdt, address(config.morphoVaults.steakhouseUsdt.vault));
    }

    function test_depositDefault_usdt_morphoV1_1_succeeds(uint256 deposit) public {
        _depositDefault_morphoOnly(deposit, config.tokens.usdt, address(config.morphoVaults.steakhouseUsdtLite.vault));
    }

    function test_depositDefault_usdc_multipleStrategiesWithdrawSome(uint256 deposit) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        defaultStrategies[2] = address(config.morphoVaults.re7Usdc.vault);

        _depositDefault_multipleStrategies(config.tokens.usdc, defaultStrategies, deposit);
    }

    function test_depositDefault_usdt_multipleStrategiesWithdrawSome(uint256 deposit) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdt.vault);
        defaultStrategies[2] = address(config.morphoVaults.steakhouseUsdtLite.vault);

        _depositDefault_multipleStrategies(config.tokens.usdt, defaultStrategies, deposit);
    }

    function test_withdrawDefault_usdc_morphoOnly_succeeds(uint256 deposit, uint256 withdrawal) public {
        _withdrawDefault_morphoOnly(
            deposit, withdrawal, config.tokens.usdc, address(config.morphoVaults.steakhouseUsdc.vault)
        );
    }

    function test_withdrawDefault_usdc_morphoV1_1_succeeds(uint256 deposit, uint256 withdrawal) public {
        _withdrawDefault_morphoOnly(deposit, withdrawal, config.tokens.usdc, address(config.morphoVaults.re7Usdc.vault));
    }

    function test_withdrawDefault_usdt_morphoOnly_succeeds(uint256 deposit, uint256 withdrawal) public {
        _withdrawDefault_morphoOnly(
            deposit, withdrawal, config.tokens.usdt, address(config.morphoVaults.steakhouseUsdt.vault)
        );
    }

    function test_withdrawDefault_usdt_morphoV1_1_succeeds(uint256 deposit, uint256 withdrawal) public {
        _withdrawDefault_morphoOnly(
            deposit, withdrawal, config.tokens.usdt, address(config.morphoVaults.steakhouseUsdtLite.vault)
        );
    }

    function test_withdrawDefault_usdc_multipleStrategiesWithdrawAll(uint256 deposit, uint256 withdrawal) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        defaultStrategies[2] = address(config.morphoVaults.re7Usdc.vault);

        _withdrawDefault_multipleStrategiesWithdrawSome(config.tokens.usdc, defaultStrategies, deposit, withdrawal);
    }

    function test_withdrawDefault_usdt_multipleStrategiesWithdrawAll(uint256 deposit, uint256 withdrawal) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdt.vault);
        defaultStrategies[2] = address(config.morphoVaults.steakhouseUsdtLite.vault);

        _withdrawDefault_multipleStrategiesWithdrawSome(config.tokens.usdt, defaultStrategies, deposit, withdrawal);
    }

    function test_rebalance_usdc_fromAave_toMorpho_succeeds(uint256 deposit) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        defaultStrategies[2] = address(config.morphoVaults.re7Usdc.vault);

        rebalance(
            config.tokens.usdc,
            defaultStrategies,
            deposit,
            address(config.periphery.aaveV3),
            address(config.morphoVaults.steakhouseUsdc.vault)
        );
    }

    function test_rebalance_usdc_fromMorpho_toAave_succeeds(uint256 deposit) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
        defaultStrategies[2] = address(config.morphoVaults.re7Usdc.vault);

        rebalance(
            config.tokens.usdc,
            defaultStrategies,
            deposit,
            address(config.morphoVaults.steakhouseUsdc.vault),
            address(config.periphery.aaveV3)
        );
    }

    function test_rebalance_usdt_betweenMorpho_succeeds(uint256 deposit) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdt.vault);
        defaultStrategies[2] = address(config.morphoVaults.steakhouseUsdtLite.vault);

        rebalance(
            config.tokens.usdt,
            defaultStrategies,
            deposit,
            address(config.morphoVaults.steakhouseUsdt.vault),
            address(config.morphoVaults.steakhouseUsdtLite.vault)
        );
    }

    function test_rebalance_usdt_fromMorpho_toAave_succeeds(uint256 deposit) public {
        address[] memory defaultStrategies = new address[](3);
        defaultStrategies[0] = address(config.periphery.aaveV3);
        defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdt.vault);
        defaultStrategies[2] = address(config.morphoVaults.steakhouseUsdtLite.vault);

        rebalance(
            config.tokens.usdt,
            defaultStrategies,
            deposit,
            address(config.morphoVaults.steakhouseUsdt.vault),
            address(config.periphery.aaveV3)
        );
    }

    // function test_rewardYield_succeeds(uint256 accrued) public {
    //     accrued = bound(accrued, 1, 100_000_000e6);

    //     deal(
    //         address(config.tokens.usdc),
    //         address(config.levelContracts.boringVault),
    //         config.tokens.usdc.balanceOf(address(config.levelContracts.boringVault)) + accrued
    //     );

    //     vm.startPrank(strategist.addr);

    //     vaultManager.depositDefault(address(config.tokens.usdc), accrued);

    //     uint256 treasuryBalanceBefore = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

    //     address[] memory assets = new address[](2);
    //     assets[0] = address(config.tokens.usdc);
    //     assets[1] = address(config.tokens.usdt);

    //     vaultManager.reward(assets);

    //     uint256 treasuryBalanceAfter = config.tokens.usdc.balanceOf(config.users.protocolTreasury);

    //     assertApproxEqAbs(treasuryBalanceAfter - treasuryBalanceBefore, accrued, 1, "Accrued amount does not match");
    // }

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

    function _getTotalAssets(address asset) public view returns (uint256) {
        if (asset == address(config.tokens.usdc)) {
            return VaultLib._getTotalAssets(vaultManager.vault(), usdcStrategies, asset);
        }
        if (asset == address(config.tokens.usdt)) {
            return VaultLib._getTotalAssets(vaultManager.vault(), usdtStrategies, asset);
        }
        return 0;
    }

    function _scheduleAndExecuteAdminAction(address target, bytes memory data) internal {
        vm.startPrank(config.users.admin);
        config.levelContracts.adminTimelock.schedule(target, 0, data, bytes32(0), 0, 3 days);

        vm.warp(block.timestamp + 3 days);

        config.levelContracts.adminTimelock.execute(target, 0, data, bytes32(0), 0);
        vm.stopPrank();
    }

    function _depositDefault_morphoOnly(uint256 deposit, ERC20 asset, address morphoVault) internal {
        deposit = bound(deposit, 1, INITIAL_BALANCE);

        // Set Morpho only as a default strategy
        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = morphoVault;

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature("setDefaultStrategies(address,address[])", address(asset), defaultStrategies)
        );

        assertEq(config.levelContracts.vaultManager.getDefaultStrategies(address(asset)), defaultStrategies);

        vm.startPrank(strategist.addr);

        uint256 expectedShares = ERC4626(morphoVault).previewDeposit(deposit);

        vaultManager.depositDefault(address(asset), deposit);

        assertEq(
            config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_SHARES,
            "Wrong number of vault shares"
        );
        assertEq(
            asset.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit,
            "Wrong amount of underlying"
        );
        assertEq(
            ERC4626(morphoVault).balanceOf(address(config.levelContracts.boringVault)),
            expectedShares,
            "Wrong amount of Morpho vault shares"
        );

        assertApproxEqRel(
            _getTotalAssets(address(asset)), INITIAL_BALANCE, 0.000001e18, "Wrong amount of total assets after deposit"
        );
    }

    function _withdrawDefault_morphoOnly(uint256 deposit, uint256 withdrawal, ERC20 asset, address morphoVault)
        internal
    {
        deposit = bound(deposit, 2, INITIAL_BALANCE);
        withdrawal = bound(withdrawal, 1, deposit - 1);

        // Set Morpho only as a default strategy
        address[] memory defaultStrategies = new address[](1);
        defaultStrategies[0] = morphoVault;

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature("setDefaultStrategies(address,address[])", address(asset), defaultStrategies)
        );

        vm.startPrank(strategist.addr);

        vaultManager.depositDefault(address(asset), deposit);

        vaultManager.withdrawDefault(address(asset), withdrawal);

        assertEq(
            config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_SHARES,
            "Number of shares must not change"
        );
        assertApproxEqRel(
            asset.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit + withdrawal,
            0.000001e18,
            "Wrong amount of underlying"
        );

        assertApproxEqRel(
            _getTotalAssets(address(asset)), INITIAL_BALANCE, 0.000001e18, "Wrong amount of total assets after deposit"
        );
    }

    function _depositDefault_multipleStrategies(ERC20 asset, address[] memory defaultStrategies, uint256 deposit)
        internal
    {
        deposit = bound(deposit, 2e2, INITIAL_BALANCE);

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature("setDefaultStrategies(address,address[])", address(asset), defaultStrategies)
        );

        vm.startPrank(strategist.addr);

        for (uint256 i = 0; i < defaultStrategies.length; i++) {
            vaultManager.deposit(address(asset), defaultStrategies[i], _applyPercentage(deposit, 0.333333333333333e18));
        }

        assertApproxEqAbs(
            asset.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit,
            1e6,
            "Wrong amount of underlying after deposit"
        );

        assertApproxEqRel(
            _getTotalAssets(address(asset)), INITIAL_BALANCE, 0.000001e18, "Wrong amount of total assets after deposit"
        );
    }

    function _withdrawDefault_multipleStrategiesWithdrawSome(
        ERC20 asset,
        address[] memory defaultStrategies,
        uint256 deposit,
        uint256 withdrawal
    ) public {
        deposit = bound(deposit, 2e2, INITIAL_BALANCE);
        withdrawal = bound(withdrawal, 1e2, deposit / 2);

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature("setDefaultStrategies(address,address[])", address(asset), defaultStrategies)
        );

        vm.startPrank(strategist.addr);

        for (uint256 i = 0; i < defaultStrategies.length; i++) {
            vaultManager.deposit(address(asset), defaultStrategies[i], _applyPercentage(deposit, 0.333333333333333e18));
        }

        vaultManager.withdrawDefault(address(asset), withdrawal);

        assertEq(
            config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)), INITIAL_SHARES
        );
        assertApproxEqAbs(
            asset.balanceOf(address(config.levelContracts.boringVault)),
            INITIAL_BALANCE - deposit + withdrawal,
            1e6,
            "Wrong amount after withdrawal"
        );

        assertApproxEqRel(
            _getTotalAssets(address(asset)),
            INITIAL_BALANCE,
            0.000001e18,
            "Wrong amount of total assets after withdrawal"
        );
        vm.stopPrank();
    }

    function rebalance(
        ERC20 asset,
        address[] memory defaultStrategies,
        uint256 rebalanceAmount,
        address fromStrategy,
        address toStrategy
    ) public {
        rebalanceAmount = bound(rebalanceAmount, 1, _applyPercentage(INITIAL_BALANCE, 0.33333333e18));

        _scheduleAndExecuteAdminAction(
            address(config.levelContracts.vaultManager),
            abi.encodeWithSignature("setDefaultStrategies(address,address[])", address(asset), defaultStrategies)
        );

        vm.startPrank(strategist.addr);

        for (uint256 i = 0; i < defaultStrategies.length; i++) {
            vaultManager.deposit(
                address(asset), defaultStrategies[i], _applyPercentage(INITIAL_BALANCE, 0.333333333333333e18)
            );
        }

        assertApproxEqRel(
            _getTotalAssets(address(asset)), INITIAL_BALANCE, 0.000001e18, "Wrong amount of total assets after deposit"
        );

        assertApproxEqRel(
            _getAssetsInStrategy(address(asset), fromStrategy),
            _getAssetsInStrategy(address(asset), toStrategy),
            0.000001e18,
            "Wrong amount of assets in strategy after deposit"
        );

        uint256 fromBalanceBefore = _getAssetsInStrategy(address(asset), fromStrategy);
        uint256 toBalanceBefore = _getAssetsInStrategy(address(asset), toStrategy);

        vaultManager.withdraw(address(asset), fromStrategy, rebalanceAmount);
        vaultManager.deposit(address(asset), toStrategy, rebalanceAmount);

        uint256 fromBalanceAfter = _getAssetsInStrategy(address(asset), fromStrategy);
        uint256 toBalanceAfter = _getAssetsInStrategy(address(asset), toStrategy);

        assertGt(toBalanceAfter, toBalanceBefore, "toStrategy should have more assets after rebalance");
        assertGt(fromBalanceBefore, fromBalanceAfter, "fromStrategy should have less assets after rebalance");

        assertApproxEqRel(
            _getTotalAssets(address(asset)),
            INITIAL_BALANCE,
            0.000001e18,
            "Wrong amount of total assets after rebalance"
        );
    }

    // function test_withdrawDefault_multipleStrategiesWithdrawAll(uint256 deposit) public {
    //     deposgit = bound(deposit, 2e4, INITIAL_BALANCE);

    //     ERC20 asset = config.tokens.usdc;

    //     // Set multiple default strategies
    //     address[] memory defaultStrategies = new address[](3);
    //     defaultStrategies[0] = address(config.periphery.aaveV3);
    //     defaultStrategies[1] = address(config.morphoVaults.steakhouseUsdc.vault);
    //     defaultStrategies[2] = address(config.morphoVaults.re7Usdc.vault);

    //     _scheduleAndExecuteAdminAction(
    //         address(config.levelContracts.vaultManager),
    //         abi.encodeWithSignature("setDefaultStrategies(address,address[])", address(asset), defaultStrategies)
    //     );

    //     vm.startPrank(strategist.addr);

    //     for (uint256 i = 0; i < defaultStrategies.length; i++) {
    //         uint256 deposited = vaultManager.deposit(
    //             address(asset), defaultStrategies[i], _applyPercentage(deposit, 0.3333333333333e18)
    //         );
    //         console2.log(string.concat("Deposited ", deposited, " into ", defaultStrategies[i]));
    //     }

    //     // _inspectVaultBalances();
    //     assertApproxEqAbs(
    //         asset.balanceOf(address(config.levelContracts.boringVault)),
    //         INITIAL_BALANCE - deposit,
    //         10,
    //         "Wrong amount after deposit"
    //     );

    //     // _inspectVaultBalances();
    //     vaultManager.withdrawDefault(address(asset), deposit);
    //     // _inspectVaultBalances();
    //     assertEq(
    //         config.levelContracts.boringVault.balanceOf(address(config.levelContracts.boringVault)), INITIAL_SHARES
    //     );
    //     assertApproxEqRel(
    //         asset.balanceOf(address(config.levelContracts.boringVault)),
    //         INITIAL_BALANCE,
    //         0.0001e18,
    //         "Wrong amount after withdrawal"
    //     );

    //     vm.stopPrank();
    // }

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

    function test_removeAssetStrategy_succeeds() public {
        // Get initial state
        address[] memory initialUsdcStrategies = vaultManager.getDefaultStrategies(address(config.tokens.usdc));
        assertEq(initialUsdcStrategies.length, 3, "Initial USDC strategies count should be 3");

        // Remove Aave V3 strategy (which is in defaultStrategies)
        vm.startPrank(config.users.admin);
        vaultManager.removeAssetStrategy(address(config.tokens.usdc), address(config.periphery.aaveV3));
        vm.stopPrank();

        // Verify Aave V3 was removed from defaultStrategies
        address[] memory afterAaveRemoval = vaultManager.getDefaultStrategies(address(config.tokens.usdc));
        assertEq(afterAaveRemoval.length, 2, "USDC strategies count should be 2 after removing Aave");
        assertEq(
            afterAaveRemoval[0],
            address(config.morphoVaults.steakhouseUsdc.vault),
            "First strategy should be Steakhouse"
        );
        assertEq(afterAaveRemoval[1], address(config.morphoVaults.re7Usdc.vault), "Second strategy should be Re7");

        // Verify Aave V3 was removed from assetToStrategy
        (
            StrategyCategory category,
            ERC20 baseCollateral,
            ERC20 receiptToken,
            AggregatorV3Interface oracle,
            address depositContract,
            address withdrawContract,
            uint256 heartbeat
        ) = vaultManager.assetToStrategy(address(config.tokens.usdc), address(config.periphery.aaveV3));
        assertEq(
            uint256(category), uint256(StrategyCategory.UNDEFINED), "Aave strategy should be undefined after removal"
        );

        // Remove Re7 strategy
        vm.startPrank(config.users.admin);
        vaultManager.removeAssetStrategy(address(config.tokens.usdc), address(config.morphoVaults.re7Usdc.vault));
        vm.stopPrank();

        // Verify Re7 was removed from defaultStrategies
        address[] memory afterRe7Removal = vaultManager.getDefaultStrategies(address(config.tokens.usdc));
        assertEq(afterRe7Removal.length, 1, "USDC strategies count should be 1 after removing Re7");
        assertEq(
            afterRe7Removal[0], address(config.morphoVaults.steakhouseUsdc.vault), "Only strategy should be Steakhouse"
        );

        // Verify Re7 was removed from assetToStrategy
        (category, baseCollateral, receiptToken, oracle, depositContract, withdrawContract, heartbeat) =
            vaultManager.assetToStrategy(address(config.tokens.usdc), address(config.morphoVaults.re7Usdc.vault));
        assertEq(
            uint256(category), uint256(StrategyCategory.UNDEFINED), "Re7 strategy should be undefined after removal"
        );
    }
}

/**
 * Test cases to add
 * - Test what happens when there is not enough liquidity to withdraw from Morpho
 * - Test what happens when there is not enough liquidity to withdraw from Aave
 */
