// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {Test, Vm} from "forge-std/Test.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {Utils} from "@level/test/utils/Utils.sol";
import {lvlUSD} from "@level/src/v1/lvlUSD.sol";
import {Authority} from "@solmate/src/auth/Auth.sol";

contract AuthUpgradeableACLTests is Utils, Configurable {
    Vm.Wallet private deployer;
    Vm.Wallet private normal;
    Vm.Wallet private redeemer;
    Vm.Wallet private gatekeeper;

    LevelMintingV2 public levelMinting;

    function setUp() public {
        forkMainnet(22305203);

        deployer = vm.createWallet("deployer");

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
    }

    function test_transferOwnership_succeeds() public {
        address[] memory targets = new address[](6);
        targets[0] = address(config.levelContracts.rolesAuthority);
        targets[1] = address(config.levelContracts.levelMintingV2);
        targets[2] = address(config.levelContracts.vaultManager);
        targets[3] = address(config.levelContracts.rewardsManager);
        targets[4] = address(config.levelContracts.boringVault);
        targets[5] = address(config.levelContracts.pauserGuard);

        bytes[] memory payloads = new bytes[](6);
        payloads[0] = abi.encodeWithSignature("transferOwnership(address)", deployer.addr);
        payloads[1] = abi.encodeWithSignature("transferOwnership(address)", deployer.addr);
        payloads[2] = abi.encodeWithSignature("transferOwnership(address)", deployer.addr);
        payloads[3] = abi.encodeWithSignature("transferOwnership(address)", deployer.addr);
        payloads[4] = abi.encodeWithSignature("transferOwnership(address)", deployer.addr);
        payloads[5] = abi.encodeWithSignature("transferOwnership(address)", deployer.addr);

        _scheduleAndExecuteAdminActionBatch(
            config.users.admin, address(config.levelContracts.adminTimelock), targets, payloads
        );

        assertEq(address(config.levelContracts.rolesAuthority.owner()), deployer.addr);
        assertEq(address(config.levelContracts.levelMintingV2.owner()), deployer.addr);
        assertEq(address(config.levelContracts.vaultManager.owner()), deployer.addr);
        assertEq(address(config.levelContracts.rewardsManager.owner()), deployer.addr);
        assertEq(address(config.levelContracts.boringVault.owner()), deployer.addr);
        assertEq(address(config.levelContracts.pauserGuard.owner()), deployer.addr);
    }

    function test_transferOwnership_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.levelMintingV2.transferOwnership(deployer.addr);

        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.vaultManager.transferOwnership(deployer.addr);

        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.rewardsManager.transferOwnership(deployer.addr);

        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.boringVault.transferOwnership(deployer.addr);

        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.rolesAuthority.transferOwnership(deployer.addr);

        vm.expectRevert("UNAUTHORIZED");
        config.levelContracts.pauserGuard.transferOwnership(deployer.addr);
        vm.stopPrank();
    }

    function test_setAuthority_revertsIfNotTimelock() public {
        vm.startPrank(config.users.admin);
        vm.expectRevert();
        config.levelContracts.levelMintingV2.setAuthority(Authority(address(0)));
        vm.stopPrank();

        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(config.levelContracts.levelMintingV2),
            abi.encodeWithSignature("setAuthority(address)", Authority(address(0)))
        );

        assertEq(address(config.levelContracts.levelMintingV2.authority()), address(0));
    }
}
