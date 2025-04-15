// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {Test, Vm} from "forge-std/Test.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ILevelMintingV2Errors} from "@level/src/v2/interfaces/level/ILevelMintingV2.sol";

contract LevelMintingV2AclUnitTests is Utils, Configurable {
    Vm.Wallet private deployer;
    Vm.Wallet private normal;
    Vm.Wallet private redeemer;
    Vm.Wallet private gatekeeper;

    LevelMintingV2 public levelMinting;

    address public constant DAI = 0x6b175474e89094c44dA98b95B7002f2956889026;

    function setUp() public {
        forkMainnet(22134385);

        deployer = vm.createWallet("deployer");
        vm.label(deployer.addr, "Deployer");
        normal = vm.createWallet("normal");
        vm.label(normal.addr, "Normal");
        redeemer = vm.createWallet("redeemer");
        vm.label(redeemer.addr, "Redeemer");
        gatekeeper = vm.createWallet("gatekeeper");
        vm.label(gatekeeper.addr, "Gatekeeper");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();
        _labelAddresses();

        vm.startPrank(config.users.admin);
        lvlUSD _lvlUSD = lvlUSD(address(config.tokens.lvlUsd));
        _lvlUSD.setMinter(address(config.levelContracts.levelMintingV2));
        vm.stopPrank();

        address[] memory targets = new address[](2);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.rolesAuthority);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", redeemer.addr, REDEEMER_ROLE, true);
        payloads[1] = abi.encodeWithSignature("setUserRole(address,uint8,bool)", gatekeeper.addr, GATEKEEPER_ROLE, true);

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        levelMinting = LevelMintingV2(address(config.levelContracts.levelMintingV2));
    }

    function test__initiateRedeem_revertsIfNotRedeemer() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.initiateRedeem(address(config.tokens.usdc), 1e6, 1e6);
        vm.stopPrank();
    }

    function test__maxMintPerBlock_revertsIfNotGatekeeper() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.setMaxMintPerBlock(1e6);
        vm.stopPrank();

        vm.startPrank(gatekeeper.addr);
        levelMinting.setMaxMintPerBlock(1e6);
        vm.stopPrank();
    }

    function test__maxRedeemPerBlock_revertsIfNotGatekeeper() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.setMaxRedeemPerBlock(1e6);
        vm.stopPrank();

        vm.startPrank(gatekeeper.addr);
        levelMinting.setMaxRedeemPerBlock(1e6);
        vm.stopPrank();
    }

    function test__disableMintRedeem_revertsIfNotGatekeeper() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.disableMintRedeem();
        vm.stopPrank();

        vm.startPrank(gatekeeper.addr);
        levelMinting.disableMintRedeem();
        vm.stopPrank();
    }

    function test__setBaseCollateral_revertsIfNotAdmin() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.setBaseCollateral(address(config.tokens.usdc), true);
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.setBaseCollateral(DAI, true);
        vm.stopPrank();

        assertEq(levelMinting.isBaseCollateral(address(DAI)), true);
    }

    function test__setBaseCollateral_revertsIfInvalidAddress() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(ILevelMintingV2Errors.InvalidAddress.selector);
        levelMinting.setBaseCollateral(address(0), true);
        vm.stopPrank();
    }

    function test__addMintableAsset_revertsIfNotAdmin() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.addMintableAsset(DAI);
        vm.stopPrank();
    }

    function test__addMintableAsset_revertsIfInvalidAddress() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(ILevelMintingV2Errors.InvalidAddress.selector);
        levelMinting.addMintableAsset(address(0));
        vm.stopPrank();
    }

    function test__addRedeemableAsset_revertsIfNotAdmin() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.addRedeemableAsset(DAI);
        vm.stopPrank();
    }

    function test__addRedeemableAsset_revertsIfInvalidAddress() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(ILevelMintingV2Errors.InvalidAddress.selector);
        levelMinting.addRedeemableAsset(address(0));
        vm.stopPrank();
    }

    function test__removeMintableAsset_succeedsIfAdminOrTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.addMintableAsset(DAI);
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.removeMintableAsset(DAI);
        vm.stopPrank();
    }

    function test__removeMintableAsset_revertsIfNotAdmin() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.removeMintableAsset(DAI);
        vm.stopPrank();
    }

    function test__removeRedeemableAsset_succeedsIfAdminOrTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.addRedeemableAsset(DAI);
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.stopPrank();
    }

    function test__removeRedeemableAsset_revertsIfNotAdmin() public {
        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.removeRedeemableAsset(DAI);
        vm.stopPrank();
    }

    function test__addOracle_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.addOracle(DAI, address(config.tokens.usdc), false);
        vm.stopPrank();
    }

    function test__addOracle_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.addOracle(DAI, address(config.tokens.usdc), false);
        vm.stopPrank();
    }

    function test__addOracle_revertsIfInvalidAddress() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(ILevelMintingV2Errors.InvalidAddress.selector);
        levelMinting.addOracle(address(config.tokens.usdc), address(0), false);

        vm.expectRevert(ILevelMintingV2Errors.InvalidAddress.selector);
        levelMinting.addOracle(address(0), address(config.morphoVaults.re7Usdc.oracle), false);
        vm.stopPrank();
    }

    function test__removeOracle_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.addOracle(DAI, address(config.tokens.usdc), false);
        vm.stopPrank();

        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.removeOracle(DAI);
        vm.stopPrank();
    }

    function test__removeOracle_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.removeOracle(DAI);
        vm.stopPrank();
    }

    function test__setHeartBeat_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.setHeartBeat(DAI, 1e6);
        vm.stopPrank();
    }

    function test__setHeartBeat_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.setHeartBeat(DAI, 1e6);
        vm.stopPrank();
    }

    function test__setHeartBeat_revertsIfInvalidHeartBeat() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        vm.expectRevert(ILevelMintingV2Errors.InvalidHeartBeatValue.selector);
        levelMinting.setHeartBeat(DAI, 0);
        vm.stopPrank();
    }

    function test__setCooldownDuration_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.setCooldownDuration(10 minutes);
        vm.stopPrank();
    }

    function test__setCooldownDuration_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.setCooldownDuration(10 minutes);
        vm.stopPrank();
    }

    function test__setVaultManager_succeedsIfTimelock() public {
        vm.startPrank(address(config.levelContracts.adminTimelock));
        levelMinting.setVaultManager(address(config.levelContracts.vaultManager));
        vm.stopPrank();
    }

    function test__setVaultManager_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.setVaultManager(address(config.levelContracts.vaultManager));
        vm.stopPrank();
    }

    function test__setGuard_succeedsOnlyAdmin() public {
        // Generate a new address and label it
        Vm.Wallet memory newGuard = vm.createWallet("newGuard");
        vm.label(newGuard.addr, "New Guard");

        vm.startPrank(normal.addr);
        vm.expectRevert("UNAUTHORIZED");
        levelMinting.setGuard(newGuard.addr);
        vm.stopPrank();

        vm.startPrank(config.users.admin);
        levelMinting.setGuard(newGuard.addr);
        vm.stopPrank();

        assertEq(address(levelMinting.guard()), newGuard.addr);
    }
}
