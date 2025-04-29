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

    address[] public assets;
    address[] public newBaseCollateral;

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

        // // Setup strategist
        address[] memory targets = new address[](4);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.rolesAuthority);

        bytes[] memory payloads = new bytes[](4);
        payloads[0] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, STRATEGIST_ROLE, true);
        payloads[1] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", strategist.addr, REWARDER_ROLE, true);

        _scheduleAndExecuteAdminActionBatch(
            address(config.users.admin), address(config.levelContracts.adminTimelock), targets, payloads
        );

        assets = new address[](2);
        assets[0] = address(config.tokens.usdc);
        assets[1] = address(config.tokens.usdt);

        newBaseCollateral = new address[](1);
        newBaseCollateral[0] = address(config.tokens.usdt);

        rewardsManager = config.levelContracts.rewardsManager;
        vaultManager = config.levelContracts.vaultManager;
    }

    function test_reward_revertsIfRedemptionAssetNotValid() public {
        vm.prank(address(config.levelContracts.adminTimelock));
        rewardsManager.setAllBaseCollateral(newBaseCollateral);

        vm.startPrank(strategist.addr);

        vm.expectRevert(IRewardsManagerErrors.InvalidBaseCollateral.selector);
        rewardsManager.reward(address(config.tokens.usdc), 1);
    }

    function test_setAllBaseCollateral_succeeds() public {
        address[] memory targets = new address[](2);
        targets[0] = address(rewardsManager);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSignature("setAllBaseCollateral(address[])", newBaseCollateral);

        _scheduleAndExecuteAdminActionBatch(
            address(config.users.admin), address(config.levelContracts.adminTimelock), targets, payloads
        );

        assertEq(rewardsManager.allBaseCollateral(0), newBaseCollateral[0]);

        // Assert length is 1
        vm.expectRevert();
        rewardsManager.allBaseCollateral(1);
    }

    function test_setAllBaseCollateral_revertsIfNotAdminTimelock() public {
        vm.prank(strategist.addr);
        vm.expectRevert("UNAUTHORIZED");
        rewardsManager.setAllBaseCollateral(newBaseCollateral);
    }

    function test_setAllBaseCollateral_revertsIfEmpty() public {
        address[] memory targets = new address[](2);
        targets[0] = address(rewardsManager);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSignature("setAllBaseCollateral(address[])", new address[](0));

        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(IRewardsManagerErrors.InvalidBaseCollateralArray.selector);
        rewardsManager.setAllBaseCollateral(new address[](0));
    }

    function test_setAllStrategies_revertsIfNotAdminTimelock() public {
        vm.prank(strategist.addr);
        vm.expectRevert("UNAUTHORIZED");
        rewardsManager.setAllStrategies(address(config.tokens.usdc), new StrategyConfig[](0));
    }

    function test_setAllStrategies_revertsIfAssetNotInBaseCollateral() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        rewardsManager.setAllBaseCollateral(newBaseCollateral);
        vm.expectRevert(IRewardsManagerErrors.InvalidBaseCollateral.selector);

        rewardsManager.setAllStrategies(address(config.tokens.usdc), new StrategyConfig[](0));
        vm.stopPrank();
    }

    function test_updateOracle_succeeds() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        rewardsManager.updateOracle(address(config.tokens.usdc), address(mockOracle));
        vm.stopPrank();
    }

    function test_updateOracle_revertsIfNotAdminTimelock() public {
        vm.prank(strategist.addr);
        vm.expectRevert("UNAUTHORIZED");
        rewardsManager.updateOracle(address(config.tokens.usdc), address(mockOracle));
    }

    function test_updateOracle_revertsIfInvalidAddress() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(IRewardsManagerErrors.InvalidAddress.selector);
        rewardsManager.updateOracle(address(config.tokens.usdc), address(0));

        vm.expectRevert(IRewardsManagerErrors.InvalidAddress.selector);
        rewardsManager.updateOracle(address(0), address(mockOracle));
        vm.stopPrank();
    }
}
