// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

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
import {AaveTokenOracle} from "@level/src/v2/oracles/AaveTokenOracle.sol";
import {IVaultManager} from "@level/src/v2/interfaces/level/IVaultManager.sol";
import {StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {IAllowListV2} from "@level/src/v2/interfaces/superstate/IAllowListV2.sol";

// Test minting using receipt tokens.
contract LevelMintingV2ReceiptTests is Utils, Configurable {
    using SafeTransferLib for ERC20;
    using MathLib for uint256;

    Vm.Wallet private deployer;
    Vm.Wallet private normalUser;

    uint256 public constant INITIAL_BALANCE = 500000e6;
    address public constant USTB_CHAINLINK_FEED = 0xE4fA682f94610cCd170680cc3B045d77D9E528a8;
    address public constant USTB_ALLOWLIST_ADDRESS = 0x873b548Ee1e5813dBE35898AC4d63e8b41809109;

    LevelMintingV2 public levelMinting;
    MockOracle public mockOracle;

    address[] public morphoVaults;

    function setUp() public {
        forkMainnet(22305203);

        deployer = vm.createWallet("deployer");
        normalUser = vm.createWallet("normalUser");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();

        mockOracle = new MockOracle(1e8, 8);

        morphoVaults = _allMorphoVaultAddresses();

        AaveTokenOracle aUsdcOracle = new AaveTokenOracle(address(config.tokens.usdc));

        config.morphoVaults.steakhouseUsdc.oracle =
            config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.steakhouseUsdc.vault);
        config.morphoVaults.re7Usdc.oracle =
            config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.re7Usdc.vault);
        config.morphoVaults.steakhouseUsdt.oracle =
            config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.steakhouseUsdt.vault);
        config.morphoVaults.steakhouseUsdtLite.oracle =
            config.levelContracts.erc4626OracleFactory.create(config.morphoVaults.steakhouseUsdtLite.vault);

        StrategyConfig memory steakhouseUsdtLiteConfig = StrategyConfig({
            category: StrategyCategory.MORPHO,
            baseCollateral: config.tokens.usdt,
            receiptToken: ERC20(address(config.morphoVaults.steakhouseUsdtLite.vault)),
            oracle: config.morphoVaults.steakhouseUsdtLite.oracle,
            depositContract: address(config.morphoVaults.steakhouseUsdtLite.vault),
            withdrawContract: address(config.morphoVaults.steakhouseUsdtLite.vault),
            heartbeat: 1 days
        });

        address[] memory targets = new address[](16);
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
        targets[15] = address(config.levelContracts.vaultManager);

        bytes[] memory payloads = new bytes[](16);
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
        payloads[15] = abi.encodeWithSelector(
            IVaultManager.addAssetStrategy.selector,
            address(config.tokens.usdt),
            address(config.morphoVaults.steakhouseUsdtLite.vault),
            steakhouseUsdtLiteConfig
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

        deal(
            address(config.sparkVaults.sUSDC.vault),
            normalUser.addr,
            IERC4626(config.sparkVaults.sUSDC.vault).convertToShares(INITIAL_BALANCE)
        );
        deal(address(config.tokens.ustb), normalUser.addr, INITIAL_BALANCE * 10 ** ERC20(config.tokens.ustb).decimals());
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

    // function test_mint_sparkUsdc_succeeds(uint256 _underlyingAmount) public {
    //     IERC4626 collateral = IERC4626(config.sparkVaults.sUSDC.vault);

    //     uint256 underlyingAmount = bound(_underlyingAmount, 1e3, INITIAL_BALANCE);
    //     uint256 collateralAmount = collateral.convertToShares(underlyingAmount);

    //     console2.log("_underlyingAmount", underlyingAmount);

    //     uint256 minLvlUsdAmount =
    //         _adjustAmount(underlyingAmount, collateral.asset(), address(config.tokens.lvlUsd)).mulDivUp(0.999e18, 1e18);

    //     ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
    //         beneficiary: normalUser.addr,
    //         collateral_asset: address(config.sparkVaults.sUSDC.vault),
    //         collateral_amount: collateralAmount,
    //         min_lvlusd_amount: minLvlUsdAmount
    //     });

    //     _mint_withVaultShares_succeeds(normalUser.addr, order, underlyingAmount);
    // }

    function test_mint_superstateUstb_failsWhenNotOnAllowlist(uint256 _underlyingAmount) public {
        // This test should fail as neither boringVault nor normalUser is on the allowlist for USTB

        // For redemptionIdle contract
        _mockChainlinkCall(USTB_CHAINLINK_FEED, 105e5); // 10.5 USD per USTB
        // For levelMintingV2 contract's computeRedeem()
        _mockChainlinkCall(address(config.oracles.ustb), 105e5); // 10.5 USD per USTB

        ERC20 collateral = config.tokens.ustb;
        ERC20 underlying = config.tokens.usdc;

        uint256 underlyingAmount = bound(_underlyingAmount, 1e3, 490000e6);

        // Calculate the amount of USTB for the underlying USDC amount
        (uint256 ustbAmount,) = config.periphery.ustbRedemptionIdle.calculateUstbIn(underlyingAmount);

        console2.log("ustbAmount", ustbAmount);

        uint256 minLvlUsdAmount =
            _adjustAmount(underlyingAmount, address(underlying), address(config.tokens.lvlUsd)).mulDivUp(0.999e18, 1e18);

        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: normalUser.addr,
            collateral_asset: address(collateral),
            collateral_amount: ustbAmount,
            min_lvlusd_amount: minLvlUsdAmount
        });

        ERC20(address(collateral)).safeApprove(address(config.levelContracts.boringVault), type(uint256).max);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        uint256 minted = levelMinting.mint(order);
    }

    function test_mint_superstateUstb_succeedsWithAllowlist(uint256 _collateralAmount) public {
        // This test should succeed as both boringVault and normalUser are on the allowlist for USTB

        // Superstate Allowlist V2 on Mainnet
        IAllowListV2 allowList = IAllowListV2(0x02f1fA8B196d21c7b733EB2700B825611d8A38E5);
        address[] memory addresses = new address[](1);
        addresses[0] = address(config.levelContracts.boringVault);

        // Following is an allowlisted address for USTB
        // Will act as a sender in this test
        address allowlistedAddress = USTB_ALLOWLIST_ADDRESS;

        vm.prank(allowList.owner());
        allowList.setProtocolAddressPermissions(addresses, "USTB", true);

        // For redemptionIdle contract
        _mockChainlinkCall(USTB_CHAINLINK_FEED, 105e5); // 10.5 USD per USTB
        // For levelMintingV2 contract's computeRedeem()
        _mockChainlinkCall(address(config.oracles.ustb), 105e5); // 10.5 USD per USTB

        ERC20 collateral = config.tokens.ustb;
        ERC20 underlying = config.tokens.usdc;

        // TODO: Fix this test failing with low precision
        uint256 collateralAmount = bound(_collateralAmount, 1e5, 47_000e6); // 47,000 USTB

        // Calculate the amount of USDC for the collateral amount
        (uint256 underlyingAmount,) = config.periphery.ustbRedemptionIdle.calculateUsdcOut(collateralAmount);

        deal(address(config.tokens.ustb), allowlistedAddress, collateralAmount);

        uint256 minLvlUsdAmount =
            _adjustAmount(underlyingAmount, address(underlying), address(config.tokens.lvlUsd)).mulDivUp(0.999e18, 1e18);

        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: allowlistedAddress,
            collateral_asset: address(collateral),
            collateral_amount: collateralAmount,
            min_lvlusd_amount: minLvlUsdAmount
        });

        vm.startPrank(allowlistedAddress);
        ERC20(address(collateral)).safeApprove(address(config.levelContracts.boringVault), type(uint256).max);
        uint256 minted = levelMinting.mint(order);
        vm.stopPrank();

        assertApproxEqRel(
            minted,
            underlyingAmount.mulDivDown(10 ** config.tokens.lvlUsd.decimals(), 10 ** underlying.decimals()),
            0.000001e18,
            "Minted amount does not match expected amount"
        );
        assertEq(ERC20(address(collateral)).balanceOf(allowlistedAddress), 0, "Allowlisted address should have 0 USTB");
        assertEq(
            ERC20(address(collateral)).balanceOf(address(config.levelContracts.boringVault)),
            collateralAmount,
            "Boring vault should have received USTB"
        );
        assertApproxEqRel(
            config.tokens.lvlUsd.balanceOf(allowlistedAddress),
            underlyingAmount.mulDivDown(10 ** config.tokens.lvlUsd.decimals(), 10 ** underlying.decimals()),
            0.000001e18,
            "Allowlisted address should have received lvlUSD"
        );
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
            min_lvlusd_amount: minLvlUsdAmount
        });

        _mint_withVaultShares_succeeds(normalUser.addr, order, underlyingAmount);
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
            min_lvlusd_amount: minLvlUsdAmount
        });

        _mint_withVaultShares_succeeds(normalUser.addr, order, underlyingAmount);
    }

    function _mint_withVaultShares_succeeds(
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

        assertApproxEqRel(minted, adjustedExpectedMinted, 0.000001e18, "Minted amount does not match expected amount");

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
            min_lvlusd_amount: minLvlUsdAmount
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
}
