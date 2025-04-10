// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Deployer} from "@level/src/v2/Deployer.sol";
import {RolesAuthority, Authority} from "@solmate/src/auth/authorities/RolesAuthority.sol";
import {ContractNames} from "@level/config/ContractNames.sol";
import {ContractAddresses} from "@level/config/ContractAddresses.sol";
import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

/**
 *  source .env && forge script script/DeployDeployer.s.sol:DeployDeployerScript --with-gas-price 30000000000 --slow --broadcast --etherscan-api-key $ETHERSCAN_KEY --verify
 * @dev Optionally can change `--with-gas-price` to something more reasonable
 */
contract DeployLevelDeployer is DeploymentUtils, Script {
    uint256 public chainId;
    uint256 public privateKey;

    // Contracts to deploy
    RolesAuthority public rolesAuthority;
    Deployer public deployer;

    uint8 public DEPLOYER_ROLE = 1;

    function setUp() external {
        chainId = vm.envUint("CHAIN_ID");
        _initializeAddresses(chainId);

        privateKey = _getPrivateKey(chainId);
    }

    function run() external {
        bytes memory creationCode;
        bytes memory constructorArgs;
        vm.startBroadcast(privateKey);

        deployer = new Deployer(dev0Address, Authority(address(0)));
        creationCode = type(RolesAuthority).creationCode;
        constructorArgs = abi.encode(dev0Address, Authority(address(0)));
        rolesAuthority =
            RolesAuthority(deployer.deployContract(LevelUSDReserveRolesAuthorityName, creationCode, constructorArgs, 0));

        deployer.setAuthority(rolesAuthority);

        rolesAuthority.setRoleCapability(DEPLOYER_ROLE, address(deployer), Deployer.deployContract.selector, true);
        rolesAuthority.setUserRole(dev0Address, DEPLOYER_ROLE, true);

        _printDeployedContracts(chainId, LevelUSDReserveDeployer, address(deployer));

        vm.stopBroadcast();
    }
}
