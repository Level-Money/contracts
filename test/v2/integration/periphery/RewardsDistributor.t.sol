// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test, Vm} from "forge-std/Test.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {ERC20 as OpenZeppelinERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20 as SolmateERC20} from "@solmate/src/tokens/ERC20.sol";
import {RewardsDistributor} from "@level/src/v2/periphery/RewardsDistributor.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RewardsDistributorTests is Utils, Configurable {
    using SafeERC20 for OpenZeppelinERC20;
    using MathLib for uint256;

    Vm.Wallet private deployer;

    RewardsDistributor public distributor;

    uint256 public constant INITIAL_BALANCE = 1000e6;

    function setUp() public {
        forkMainnet(22464604);

        deployer = vm.createWallet("deployer");

        // Use Mainnet config
        initConfig(1);

        vm.startPrank(config.users.admin);
        distributor = new RewardsDistributor(
            address(config.levelContracts.levelMintingV2), address(config.levelContracts.rewardsManager)
        );

        vm.stopPrank();
    }

    function test__mint__usdc() public {
        vm.startPrank(deployer.addr);
        deal(address(config.tokens.usdc), address(deployer.addr), INITIAL_BALANCE);
        OpenZeppelinERC20(address(config.tokens.usdc)).forceApprove(address(distributor), INITIAL_BALANCE);
        uint256 lvlUsdMinted = distributor.mint(OpenZeppelinERC20(address(config.tokens.usdc)));
        vm.stopPrank();

        assertApproxEqRel(
            config.tokens.lvlUsd.balanceOf(deployer.addr),
            INITIAL_BALANCE.convertDecimalsDown(config.tokens.usdc.decimals(), config.tokens.lvlUsd.decimals()),
            0.00002e18
        );
    }

    function test__mint__usdt() public {
        vm.startPrank(deployer.addr);
        deal(address(config.tokens.usdt), address(deployer.addr), INITIAL_BALANCE);
        OpenZeppelinERC20(address(config.tokens.usdt)).forceApprove(address(distributor), INITIAL_BALANCE);
        uint256 lvlUsdMinted = distributor.mint(OpenZeppelinERC20(address(config.tokens.usdt)));
        vm.stopPrank();

        assertApproxEqRel(
            config.tokens.lvlUsd.balanceOf(deployer.addr),
            INITIAL_BALANCE.convertDecimalsDown(config.tokens.usdt.decimals(), config.tokens.lvlUsd.decimals()),
            0.00001e18
        );
    }

    function test__getAccruedYield() public {
        address[] memory assets = new address[](2);
        assets[0] = address(config.tokens.usdc);
        assets[1] = address(config.tokens.usdt);
        uint256 accruedYield = distributor.getAccruedYield(assets);

        assertEq(accruedYield, 833008702674735395344);

        vm.startPrank(config.users.protocolTreasury);
        uint256 yieldFromRewardsManager = config.levelContracts.rewardsManager.getAccruedYield(assets);

        assertEq(accruedYield, yieldFromRewardsManager);

        vm.stopPrank();
    }
}
