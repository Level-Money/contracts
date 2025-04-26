// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {Test, Vm} from "forge-std/Test.sol";
import {DeployLevel} from "@level/script/v2/DeployLevel.s.sol";
import {Configurable} from "@level/config/Configurable.sol";
import {console2} from "forge-std/console2.sol";

import {Utils} from "@level/test/utils/Utils.sol";
import {IMorphoChainlinkOracleV2} from "@level/src/v2/interfaces/morpho/IMorphoChainlinkOracleV2.sol";

contract VerifyDeployment is Utils, Configurable {
    Vm.Wallet private deployer;

    function setUp() public {
        forkMainnet(22305203);

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

    function test__timelockOnlyOwnsItself() public {
        assertTrue(
            config.levelContracts.adminTimelock.hasRole(
                config.levelContracts.adminTimelock.DEFAULT_ADMIN_ROLE(), address(config.levelContracts.adminTimelock)
            )
        );

        assertFalse(
            config.levelContracts.adminTimelock.hasRole(
                config.levelContracts.adminTimelock.DEFAULT_ADMIN_ROLE(), address(config.users.deployer)
            )
        );

        assertFalse(
            config.levelContracts.adminTimelock.hasRole(
                config.levelContracts.adminTimelock.DEFAULT_ADMIN_ROLE(), address(config.users.admin)
            )
        );
    }

    function test__adminCanProposeAndCancel() public {
        bytes32 id = _scheduleAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(config.levelContracts.adminTimelock),
            abi.encodeWithSignature("updateDelay(uint256)", 1)
        );

        assertTrue(config.levelContracts.adminTimelock.isOperationPending(id));

        vm.startPrank(config.users.admin);
        config.levelContracts.adminTimelock.cancel(id);
        vm.stopPrank();

        assertFalse(config.levelContracts.adminTimelock.isOperationPending(id));
    }

    function test__onlyTimelockCanUpdateDelay() public {
        vm.prank(config.users.admin);

        vm.expectRevert();
        config.levelContracts.adminTimelock.updateDelay(1);

        _scheduleAndExecuteAdminAction(
            config.users.admin,
            address(config.levelContracts.adminTimelock),
            address(config.levelContracts.adminTimelock),
            abi.encodeWithSignature("updateDelay(uint256)", 1)
        );

        assertEq(config.levelContracts.adminTimelock.getMinDelay(), 1);
    }

    function test__allContractsHaveCorrectAuthority() public {
        // Only owner should be able to call RolesAuthority functions
        // But we need ADMIN_MULTISIG_ROLE to be able to call removeUserRole
        // All other rolesAuthority functions are only callable by the owner
        assertEq(
            address(config.levelContracts.rolesAuthority.authority()), address(config.levelContracts.rolesAuthority)
        );

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
        _doesUserHaveRole(address(config.levelContracts.vaultManager), VAULT_MANAGER_ROLE);

        _doesUserHaveRole(config.users.operator, STRATEGIST_ROLE);
    }

    function test__levelMintingV2__hasCorrectRoles() public {
        _doesUserHaveRole(address(config.levelContracts.levelMintingV2), VAULT_MINTER_ROLE);
        _doesUserHaveRole(address(config.levelContracts.levelMintingV2), VAULT_REDEEMER_ROLE);
    }

    function test__rewardsManager__hasCorrectRoles() public {
        _doesUserHaveRole(address(config.levelContracts.rewardsManager), VAULT_MANAGER_ROLE);
        _doesUserHaveRole(address(config.levelContracts.rewardsManager), VAULT_REDEEMER_ROLE);

        _doesUserHaveRole(config.users.operator, REWARDER_ROLE);
    }

    function test__pauserGuard__hasCorrectRoles() public {
        // Check if addresses have the correct roles
        _doesUserHaveRole(address(config.users.admin), PAUSER_ROLE);
        _doesUserHaveRole(address(config.users.operator), PAUSER_ROLE);
        _doesUserHaveRole(address(config.users.hexagateGatekeepers[0]), PAUSER_ROLE);
        _doesUserHaveRole(address(config.users.hexagateGatekeepers[1]), PAUSER_ROLE);
        _doesUserHaveRole(address(config.users.admin), UNPAUSER_ROLE);

        // Check if roles have been set correctly
        _doesRoleHaveCapability(
            address(config.levelContracts.pauserGuard),
            PAUSER_ROLE,
            bytes4(abi.encodeWithSignature("pauseGroup(bytes32)"))
        );
        _doesRoleHaveCapability(
            address(config.levelContracts.pauserGuard),
            UNPAUSER_ROLE,
            bytes4(abi.encodeWithSignature("unpauseGroup(bytes32)"))
        );
        _doesRoleHaveCapability(
            address(config.levelContracts.pauserGuard),
            PAUSER_ROLE,
            bytes4(abi.encodeWithSignature("pauseSelector(address,bytes4)"))
        );
        _doesRoleHaveCapability(
            address(config.levelContracts.pauserGuard),
            UNPAUSER_ROLE,
            bytes4(abi.encodeWithSignature("unpauseSelector(address,bytes4)"))
        );
    }

    function test__pause__levelReserveLensMorphoOracle__returnsDollar() public {
        IMorphoChainlinkOracleV2 lvlUsdOracle = IMorphoChainlinkOracleV2(0x6779b2F08611906FcE70c70c596e05859701235d);
        IMorphoChainlinkOracleV2 slvlUsdOracle = IMorphoChainlinkOracleV2(0x50356C32c984BF921a0eFB1F4264Ac328e429c2c);

        IMorphoChainlinkOracleV2 ptLvlUsdUsdcOracle =
            IMorphoChainlinkOracleV2(0xC0EFB90F40e8Dd4CB3bC20837D30E388549a8405);
        IMorphoChainlinkOracleV2 ptLvlUsdLvlUsdOracle =
            IMorphoChainlinkOracleV2(0x0E6D96E8aA0de4783a049d6793F33d55497c27A9);
        IMorphoChainlinkOracleV2 ptSlvlUsdOracle = IMorphoChainlinkOracleV2(0xEaAf18E3D90e1A3741376383Beb41A2081b4Cb8F);

        uint256 priceBefore_lvlUsdOracle = lvlUsdOracle.price();
        uint256 priceBefore_slvlUsdOracle = slvlUsdOracle.price();

        uint256 priceBefore_ptLvlUsdUsdcOracle = ptLvlUsdUsdcOracle.price();
        uint256 priceBefore_ptLvlUsdLvlUsdOracle = ptLvlUsdLvlUsdOracle.price();
        uint256 priceBefore_ptSlvlUsdOracle = ptSlvlUsdOracle.price();

        vm.startPrank(config.users.operator);
        config.periphery.levelReserveLensMorphoOracle.setPaused(true);
        vm.stopPrank();

        uint256 priceAfter_lvlUsdOracle = lvlUsdOracle.price();
        uint256 priceAfter_slvlUsdOracle = slvlUsdOracle.price();

        uint256 priceAfter_ptLvlUsdUsdcOracle = ptLvlUsdUsdcOracle.price();
        uint256 priceAfter_ptLvlUsdLvlUsdOracle = ptLvlUsdLvlUsdOracle.price();
        uint256 priceAfter_ptSlvlUsdOracle = ptSlvlUsdOracle.price();

        assertEq(priceBefore_lvlUsdOracle, priceAfter_lvlUsdOracle);
        assertEq(priceBefore_slvlUsdOracle, priceAfter_slvlUsdOracle);
        assertEq(priceBefore_ptLvlUsdUsdcOracle, priceAfter_ptLvlUsdUsdcOracle);
        assertEq(priceBefore_ptLvlUsdLvlUsdOracle, priceAfter_ptLvlUsdLvlUsdOracle);
        assertEq(priceBefore_ptSlvlUsdOracle, priceAfter_ptSlvlUsdOracle);
    }

    function _doesUserHaveRole(address user, uint8 role) internal {
        assertEq(config.levelContracts.rolesAuthority.doesUserHaveRole(user, role), true);
    }

    function _doesRoleHaveCapability(address contractAddress, uint8 role, bytes4 capability) internal {
        assertEq(config.levelContracts.rolesAuthority.doesRoleHaveCapability(role, contractAddress, capability), true);
    }
}
