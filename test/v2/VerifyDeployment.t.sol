// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {Test, Vm} from "forge-std/Test.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";

import {Utils} from "@level/test/utils/Utils.sol";

contract VerifyDeployment is Utils, Configurable {
    Vm.Wallet private deployer;

    function setUp() public {
        forkMainnet(22134385);

        deployer = vm.createWallet("deployer");

        DeployLevel deployScript = new DeployLevel();

        vm.prank(deployer.addr);
        deployScript.setUp_(1, deployer.privateKey);

        config = deployScript.run();
        _labelAddresses();
    }

    function test__allContractsOwnedByTimelock() public {
        assertNotEq(address(config.levelContracts.adminTimelock), address(0));

        assertEq(config.levelContracts.rolesAuthority.owner(), address(config.levelContracts.adminTimelock));
        assertEq(config.levelContracts.boringVault.owner(), address(config.levelContracts.adminTimelock));
        assertEq(config.levelContracts.vaultManager.owner(), address(config.levelContracts.adminTimelock));
        assertEq(config.levelContracts.rewardsManager.owner(), address(config.levelContracts.adminTimelock));
        assertEq(config.levelContracts.levelMintingV2.owner(), address(config.levelContracts.adminTimelock));
        assertEq(config.levelContracts.pauserGuard.owner(), address(config.levelContracts.adminTimelock));
    }

    function test__allContractsHaveCorrectAuthority() public {
        // Only owner should be able to call RolesAuthority functions
        assertEq(address(config.levelContracts.rolesAuthority.authority()), address(0));

        // All contracts should have the RolesAuthority as their authority
        assertEq(address(config.levelContracts.boringVault.authority()), address(config.levelContracts.rolesAuthority));
        assertEq(address(config.levelContracts.vaultManager.authority()), address(config.levelContracts.rolesAuthority));
        assertEq(
            address(config.levelContracts.rewardsManager.authority()), address(config.levelContracts.rolesAuthority)
        );
        assertEq(
            address(config.levelContracts.levelMintingV2.authority()), address(config.levelContracts.rolesAuthority)
        );
        assertEq(address(config.levelContracts.pauserGuard.authority()), address(config.levelContracts.rolesAuthority));
    }

    function test__existingRedeemersAreSet() public {
        address[16] memory redeemers = [
            0xe9AF0428143E4509df4379Bd10C4850b223F2EcB,
            0xa0D26cD3Dfbe4d8edf9f95BD9129D5f733A9D9a7,
            0x5788817BcF6482da4E434e1CEF68E6f85a690b58,
            0x6fA5d361Ab8165347F636217001E22a7cEF09B48,
            0x3D3eb99C278C7A50d8cf5fE7eBF0AD69066Fb7d1,
            0xa58627a29bb59743cE1D781B1072c59bb1dda86d,
            0xE0b7DEab801D864650DEc58CbD1b3c441D058C79,
            0xaebb8FDBD5E52F99630cEBB80D0a1c19892EB4C2,
            0x562BCF627F8dD07E0bC71f82f6fCB60737f87E07,
            0x3be3A8613dC18554a73773a5Bfb8E9819d360Dc0,
            0x5bB2719f3282EC4EA21DC2D8d790c9eA6581F3D7,
            0x48035c02b450d24D8d8953Bc1A0B6C53571bA665,
            0xd7583E3CF08bbcaB66F1242195227bBf9F865Fda,
            0xbc0f3B23930fff9f4894914bD745ABAbA9588265,
            0x79B94C17d8178689Df8d10754d7e4A1Bb3D49bc1,
            0x7FE4b2632f5AE6d930677D662AF26Bc0a06672b3
        ];

        for (uint256 i = 0; i < redeemers.length; i++) {
            assertEq(config.levelContracts.rolesAuthority.doesUserHaveRole(redeemers[i], REDEEMER_ROLE), true);
        }
    }

    function test__vaultManager__hasCorrectRoles() public {
        assertEq(
            config.levelContracts.rolesAuthority.doesUserHaveRole(
                address(config.levelContracts.vaultManager), VAULT_MANAGER_ROLE
            ),
            true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesUserHaveRole(
                address(config.levelContracts.levelMintingV2), VAULT_MINTER_ROLE
            ),
            true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesUserHaveRole(
                address(config.levelContracts.levelMintingV2), VAULT_REDEEMER_ROLE
            ),
            true
        );
    }

    function test__pauserGuard__hasCorrectRoles() public {
        // Check if addresses have the correct roles
        assertEq(config.levelContracts.rolesAuthority.doesUserHaveRole(address(config.users.admin), PAUSER_ROLE), true);
        assertEq(
            config.levelContracts.rolesAuthority.doesUserHaveRole(address(config.users.operator), PAUSER_ROLE), true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesUserHaveRole(
                address(config.users.hexagateGatekeepers[0]), PAUSER_ROLE
            ),
            true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesUserHaveRole(
                address(config.users.hexagateGatekeepers[1]), PAUSER_ROLE
            ),
            true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesUserHaveRole(address(config.users.admin), UNPAUSER_ROLE), true
        );

        // Check if roles have been set correctly
        assertEq(
            config.levelContracts.rolesAuthority.doesRoleHaveCapability(
                PAUSER_ROLE,
                address(config.levelContracts.pauserGuard),
                bytes4(abi.encodeWithSignature("pauseGroup(bytes32)"))
            ),
            true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesRoleHaveCapability(
                UNPAUSER_ROLE,
                address(config.levelContracts.pauserGuard),
                bytes4(abi.encodeWithSignature("unpauseGroup(bytes32)"))
            ),
            true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesRoleHaveCapability(
                PAUSER_ROLE,
                address(config.levelContracts.pauserGuard),
                bytes4(abi.encodeWithSignature("pauseSelector(address,bytes4)"))
            ),
            true
        );
        assertEq(
            config.levelContracts.rolesAuthority.doesRoleHaveCapability(
                UNPAUSER_ROLE,
                address(config.levelContracts.pauserGuard),
                bytes4(abi.encodeWithSignature("unpauseSelector(address,bytes4)"))
            ),
            true
        );
    }
}
