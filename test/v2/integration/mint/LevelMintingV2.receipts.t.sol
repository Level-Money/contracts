// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {stdStorage, StdStorage, Test, Vm} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {
    ILevelMintingV2,
    ILevelMintingV2Structs,
    ILevelMintingV2Errors
} from "@level/src/v2/interfaces/ILevelMintingV2.sol";
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
import {AaveTokenOracle} from "@level/src/v2/oracles/AaveTokenOracle.sol";

// Test minting using receipt tokens.
contract LevelMintingV2ReceiptTests is Utils, Configurable {
    using SafeTransferLib for ERC20;
    using MathLib for uint256;

    Vm.Wallet private deployer;
    Vm.Wallet private normalUser;

    uint256 public constant INITIAL_BALANCE = 500000e6;

    LevelMintingV2 public levelMinting;
    MockOracle public mockOracle;
    // MockERC4626 public mockUsdcERC4626;

    address[] public morphoVaults;

    function setUp() public {
        forkMainnet(22134385);

        deployer = vm.createWallet("deployer");
        normalUser = vm.createWallet("normalUser");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        mockOracle = new MockOracle(1e8, 8);
        // mockUsdcERC4626 = new MockERC4626(IERC20(address(config.tokens.usdc)));

        morphoVaults = _allMorphoVaultAddresses();

        AaveTokenOracle aUsdcOracle = new AaveTokenOracle(address(config.tokens.usdc));

        // config.morphoVaults.steakhouseUsdc.oracle = new ERC4626Oracle(mockUsdcERC4626, 4 hours);
        // config.morphoVaults.re7Usdc.oracle = new ERC4626Oracle(mockUsdcERC4626, 4 hours);
        // config.morphoVaults.steakhouseUsdt.oracle = new ERC4626Oracle(mockUsdcERC4626, 4 hours);
        // config.morphoVaults.steakhouseUsdtLite.oracle = new ERC4626Oracle(mockUsdcERC4626, 4 hours);

        // config.morphoVaults.steakhouseUsdc.oracle =
        //     config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.steakhouseUsdc.vault, 4 hours);
        // config.morphoVaults.re7Usdc.oracle =
        //     config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.re7Usdc.vault, 4 hours);
        // config.morphoVaults.steakhouseUsdt.oracle =
        //     config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.steakhouseUsdt.vault, 4 hours);
        // config.morphoVaults.steakhouseUsdtLite.oracle =
        //     config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.steakhouseUsdtLite.vault, 4 hours);

        address[] memory targets = new address[](15);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.levelMintingV2);
        targets[2] = address(config.levelContracts.levelMintingV2);
        targets[3] = address(config.levelContracts.levelMintingV2);
        targets[4] = address(config.levelContracts.levelMintingV2);
        targets[5] = address(config.levelContracts.levelMintingV2);
        targets[6] = address(config.levelContracts.levelMintingV2);
        targets[7] = address(config.levelContracts.levelMintingV2);
        targets[8] = address(config.levelContracts.levelMintingV2);
        targets[9] = address(config.levelContracts.levelMintingV2);
        targets[10] = address(config.levelContracts.levelMintingV2);
        targets[11] = address(config.levelContracts.levelMintingV2);
        targets[12] = address(config.levelContracts.levelMintingV2);
        targets[13] = address(config.levelContracts.levelMintingV2);
        targets[14] = address(config.levelContracts.levelMintingV2);

        bytes[] memory payloads = new bytes[](15);
        payloads[0] =
            abi.encodeWithSignature("setUserRole(address,uint8,bool)", address(normalUser.addr), REDEEMER_ROLE, true);
        payloads[1] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdc), address(mockOracle), false
        );
        payloads[2] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.usdt), address(mockOracle), false
        );
        payloads[3] =
            abi.encodeWithSignature("addMintableAsset(address)", address(config.morphoVaults.steakhouseUsdc.vault));
        payloads[4] = abi.encodeWithSignature("addMintableAsset(address)", address(config.tokens.aUsdc));
        payloads[5] =
            abi.encodeWithSignature("addMintableAsset(address)", address(config.morphoVaults.steakhouseUsdt.vault));
        payloads[6] =
            abi.encodeWithSignature("addMintableAsset(address)", address(config.morphoVaults.steakhouseUsdtLite.vault));
        payloads[7] = abi.encodeWithSignature(
            "addOracle(address,address,bool)",
            address(config.morphoVaults.steakhouseUsdc.vault),
            address(config.morphoVaults.steakhouseUsdc.oracle),
            true
        );
        payloads[8] = abi.encodeWithSignature(
            "addOracle(address,address,bool)", address(config.tokens.aUsdc), address(aUsdcOracle), true
        );
        payloads[9] = abi.encodeWithSignature(
            "addOracle(address,address,bool)",
            address(config.morphoVaults.steakhouseUsdt.vault),
            address(config.morphoVaults.steakhouseUsdt.oracle),
            true
        );
        payloads[10] = abi.encodeWithSignature(
            "addOracle(address,address,bool)",
            address(config.morphoVaults.steakhouseUsdtLite.vault),
            address(config.morphoVaults.steakhouseUsdtLite.oracle),
            true
        );
        payloads[11] = abi.encodeWithSignature(
            "setHeartBeat(address,uint256)", address(config.morphoVaults.steakhouseUsdc.vault), 1 days
        );
        payloads[12] = abi.encodeWithSignature("setHeartBeat(address,uint256)", address(config.tokens.aUsdc), 1 days);
        payloads[13] = abi.encodeWithSignature(
            "setHeartBeat(address,uint256)", address(config.morphoVaults.steakhouseUsdt.vault), 1 days
        );
        payloads[14] = abi.encodeWithSignature(
            "setHeartBeat(address,uint256)", address(config.morphoVaults.steakhouseUsdtLite.vault), 1 days
        );

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        vm.startPrank(config.users.admin);
        lvlUSD _lvlUSD = lvlUSD(address(config.tokens.lvlUsd));
        _lvlUSD.setMinter(address(config.levelContracts.levelMintingV2));
        vm.stopPrank();

        for (uint256 i = 0; i < morphoVaults.length; i++) {
            deal(morphoVaults[i], normalUser.addr, IERC4626(morphoVaults[i]).convertToShares(INITIAL_BALANCE));
        }

        deal(address(config.tokens.usdc), normalUser.addr, INITIAL_BALANCE * 10 ** ERC20(config.tokens.usdc).decimals());
        deal(address(config.tokens.usdt), normalUser.addr, INITIAL_BALANCE * 10 ** ERC20(config.tokens.usdt).decimals());

        vm.startPrank(normalUser.addr);
        ERC20(config.tokens.usdc).approve(address(config.periphery.aaveV3), INITIAL_BALANCE);
        config.periphery.aaveV3.supply(address(config.tokens.usdc), INITIAL_BALANCE, normalUser.addr, 0);
        vm.stopPrank();

        config.morphoVaults.steakhouseUsdc.oracle.update();
        config.morphoVaults.steakhouseUsdt.oracle.update();
        config.morphoVaults.steakhouseUsdtLite.oracle.update();
        config.morphoVaults.re7Usdc.oracle.update();

        levelMinting = LevelMintingV2(address(config.levelContracts.levelMintingV2));
    }

    function test_mint_steakhouseUsdc_succeeds(uint256 _underlyingAmount) public {
        IERC4626 collateral = IERC4626(config.morphoVaults.steakhouseUsdc.vault);

        uint256 underlyingAmount = bound(_underlyingAmount, 1e3, INITIAL_BALANCE);
        uint256 collateralAmount = collateral.convertToShares(underlyingAmount);

        console2.log("_underlyingAmount", underlyingAmount);

        uint256 minLvlUsdAmount =
            _adjustAmount(underlyingAmount, collateral.asset(), address(config.tokens.lvlUsd)).mulDivUp(0.999e18, 1e18);

        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(config.morphoVaults.steakhouseUsdc.vault),
            collateral_amount: collateralAmount,
            lvlusd_amount: minLvlUsdAmount
        });

        _mint_withMorphoVaultShares_succeeds(normalUser.addr, order, underlyingAmount);
    }

    function test_mint_steakhouseUsdtLite_succeeds(uint256 _underlyingAmount) public {
        IERC4626 collateral = IERC4626(config.morphoVaults.steakhouseUsdtLite.vault);

        uint256 underlyingAmount = bound(_underlyingAmount, 1e4, INITIAL_BALANCE);
        uint256 collateralAmount = collateral.convertToShares(underlyingAmount);

        uint256 minLvlUsdAmount =
            _adjustAmount(underlyingAmount, collateral.asset(), address(config.tokens.lvlUsd)).mulDivUp(0.999e18, 1e18);

        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(config.morphoVaults.steakhouseUsdtLite.vault),
            collateral_amount: collateralAmount,
            lvlusd_amount: minLvlUsdAmount
        });

        _mint_withMorphoVaultShares_succeeds(normalUser.addr, order, underlyingAmount);
    }

    function _mint_withMorphoVaultShares_succeeds(
        address caller,
        ILevelMintingV2Structs.Order memory order,
        uint256 underlyingAmount
    ) internal {
        vm.startPrank(caller);
        IERC4626 collateral = IERC4626(order.collateral_asset);

        ERC20(address(collateral)).safeApprove(address(config.levelContracts.boringVault), type(uint256).max);

        uint256 minted = levelMinting.mint(order);

        (int256 underlyingPrice, uint256 underlyingDecimals) = levelMinting.getPriceAndDecimals(collateral.asset());

        uint256 expectedMinted = underlyingAmount.mulDivDown(
            10 ** config.tokens.lvlUsd.decimals(), 10 ** ERC20(collateral.asset()).decimals()
        );

        uint256 adjustedExpectedMinted = expectedMinted.mulDivDown(uint256(underlyingPrice), 10 ** underlyingDecimals);

        // TODO: tighten this slippage
        assertApproxEqRel(minted, adjustedExpectedMinted, 0.001e18, "Minted amount does not match expected amount");

        vm.stopPrank();
    }

    function test_mint_aUsdc_succeeds(uint256 _underlyingAmount) public {
        ERC20 collateral = config.tokens.aUsdc;
        ERC20 underlying = config.tokens.usdc;

        uint256 underlyingAmount = bound(_underlyingAmount, 1, INITIAL_BALANCE);
        uint256 collateralAmount = underlyingAmount;

        uint256 minLvlUsdAmount =
            _adjustAmount(underlyingAmount, address(underlying), address(config.tokens.lvlUsd)).mulDivUp(0.999e18, 1e18);

        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(collateral),
            collateral_amount: collateralAmount,
            lvlusd_amount: minLvlUsdAmount
        });

        vm.startPrank(normalUser.addr);

        ERC20(address(collateral)).safeApprove(address(config.levelContracts.boringVault), type(uint256).max);

        uint256 minted = levelMinting.mint(order);

        (int256 underlyingPrice, uint256 underlyingDecimals) = levelMinting.getPriceAndDecimals(address(underlying));

        uint256 expectedMinted =
            underlyingAmount.mulDivDown(10 ** config.tokens.lvlUsd.decimals(), 10 ** underlying.decimals());

        uint256 adjustedExpectedMinted = expectedMinted.mulDivDown(uint256(underlyingPrice), 10 ** underlyingDecimals);

        assertApproxEqAbs(minted, adjustedExpectedMinted, 1, "Minted amount does not match expected amount");

        vm.stopPrank();
    }
}
