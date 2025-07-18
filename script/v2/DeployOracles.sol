// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {CappedOneDollarOracle} from "@level/src/v2/oracles/CappedOneDollarOracle.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AaveUmbrellaOracle} from "@level/src/v2/oracles/AaveUmbrellaOracle.sol";

import {DeploymentUtils} from "@level/script/v2/DeploymentUtils.s.sol";
import {Configurable} from "@level/config/Configurable.sol";

import {console2} from "forge-std/console2.sol";

/// @notice Script used to deploy new oracles required after v2 changes
/// @notice This script is meant to be used for mainnet deployments. Not a testing script.
contract DeployOracles is Configurable, DeploymentUtils, Script {
    uint256 public chainId;

    Vm.Wallet public deployerWallet;

    error InvalidProxyAddress();
    error UpgradeFailed();
    error VerificationFailed();

    function setUp() external {
        uint256 _chainId = vm.envUint("CHAIN_ID");
        setUp_(_chainId);
    }

    function setUp_(uint256 _chainId) public {
        chainId = _chainId;
        initConfig(_chainId);

        vm.label(msg.sender, "Deployer EOA");
    }

    function setUp_(uint256 _chainId, uint256 _privateKey) public {
        chainId = _chainId;
        initConfig(_chainId);

        if (msg.sender != vm.addr(_privateKey)) {
            revert("Private key does not match sender");
        }

        deployerWallet.privateKey = _privateKey;
        deployerWallet.addr = vm.addr(_privateKey);

        vm.label(msg.sender, "Deployer EOA");
    }

    function run() external {
        return upgrade();
    }

    function upgrade() public {
        vm.startBroadcast(deployerWallet.privateKey);

        // Deploy CappedMNavOracle
        CappedOneDollarOracle mNavOracle = new CappedOneDollarOracle(address(config.oracles.mNav));
        vm.label(address(mNavOracle), "CappedMNavOracle");
        console2.log("CappedMNavOracle deployed to: %s", address(mNavOracle));

        // Deploy sUsdcOracle
        config.sparkVaults.sUsdc.oracle = deployERC4626Oracle(config.sparkVaults.sUsdc.vault);
        console2.log("sUsdcOracle deployed to: %s", address(config.sparkVaults.sUsdc.oracle));

        // Deploy waUsdcStakeTokenOracle
        AaveUmbrellaOracle oracle = new AaveUmbrellaOracle(config.umbrellaVaults.waUsdcStakeToken.vault);
        config.umbrellaVaults.waUsdcStakeToken.oracle = IERC4626Oracle(address(oracle));
        console2.log("waUsdcStakeTokenOracle deployed to: %s", address(config.umbrellaVaults.waUsdcStakeToken.oracle));

        AaveUmbrellaOracle oracleUsdt = new AaveUmbrellaOracle(config.umbrellaVaults.waUsdtStakeToken.vault);
        config.umbrellaVaults.waUsdtStakeToken.oracle = IERC4626Oracle(address(oracleUsdt));
        console2.log("waUsdtStakeTokenOracle deployed to: %s", address(config.umbrellaVaults.waUsdtStakeToken.oracle));

        vm.stopBroadcast();
    }

    function verify() public view {
        // TODO: Add verification logic here
    }

    function deployERC4626Oracle(IERC4626 vault) public returns (IERC4626Oracle) {
        if (address(config.levelContracts.erc4626OracleFactory) == address(0)) {
            revert("ERC4626OracleFactory must be deployed first");
        }

        IERC4626Oracle _erc4626Oracle = IERC4626Oracle(config.levelContracts.erc4626OracleFactory.create(vault));
        vm.label(address(_erc4626Oracle), string.concat(vault.name(), " Oracle"));

        return _erc4626Oracle;
    }
}
