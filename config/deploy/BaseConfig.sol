// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

import {stdJson} from "forge-std/StdJson.sol";

import {console2} from "forge-std/console2.sol";
import {IPool} from "@level/src/v2/interfaces/aave/IPool.sol";
import {IRedemption} from "@level/src/v2/interfaces/superstate/IRedemption.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC4626OracleFactory} from "@level/src/v2/oracles/ERC4626OracleFactory.sol";

import {IMetaMorpho} from "@level/src/v2/interfaces/morpho/IMetaMorpho.sol";
import {IMetaMorphoV1_1} from "@level/src/v2/interfaces/morpho/IMetaMorphoV1_1.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";
import {StrictRolesAuthority} from "@level/src/v2/auth/StrictRolesAuthority.sol";
import {LevelReserveLens} from "@level/src/v2/lens/LevelReserveLens.sol";
import {LevelReserveLensMorphoOracle} from "@level/src/v1/lens/LevelReserveLensMorphoOracle.sol";
import {ISwapRouter} from "@level/src/v2/interfaces/uniswap/ISwapRouter.sol";
import {SwapManager} from "@level/src/v2/usd/SwapManager.sol";

contract BaseConfig {
    using stdJson for string;

    struct Config {
        uint256 chainId;
        Tokens tokens;
        Users users;
        LevelContracts levelContracts;
        PeripheryContracts periphery;
        MorphoVaults morphoVaults;
        SparkVaults sparkVaults;
        UmbrellaVaults umbrellaVaults;
        Oracles oracles;
    }

    struct Tokens {
        ERC20 usdc;
        ERC20 usdt;
        ERC20 lvlUsd;
        ERC20 slvlUsd;
        ERC20 aUsdc;
        ERC20 aUsdt;
        ERC20 ustb;
        ERC20 wrappedM;
    }

    struct UmbrellaVaults {
        ERC4626Vault waUsdcStakeToken;
        ERC4626Vault waUsdtStakeToken;
    }

    struct SparkVaults {
        ERC4626Vault sUsdc;
    }

    struct ERC4626Vault {
        IERC4626 vault;
        IERC4626Oracle oracle;
    }

    struct Users {
        address admin;
        address deployer;
        address operator;
        address protocolTreasury;
        address[] hexagateGatekeepers;
    }

    struct LevelContracts {
        StrictRolesAuthority rolesAuthority;
        LevelMintingV2 levelMintingV2;
        BoringVault boringVault;
        VaultManager vaultManager;
        RewardsManager rewardsManager;
        TimelockController adminTimelock;
        ERC4626OracleFactory erc4626OracleFactory;
        PauserGuard pauserGuard;
        LevelReserveLens levelReserveLens;
        SwapManager swapManager;
    }

    struct MorphoVaults {
        MetaMorphoVault steakhouseUsdc;
        MetaMorphoVault steakhouseUsdt;
        MetaMorphoV1_1Vault re7Usdc;
        MetaMorphoV1_1Vault steakhouseUsdtLite;
    }

    struct MetaMorphoVault {
        IMetaMorpho vault;
        IERC4626Oracle oracle;
    }

    struct MetaMorphoV1_1Vault {
        IMetaMorphoV1_1 vault;
        IERC4626Oracle oracle;
    }

    struct PeripheryContracts {
        IPool aaveV3;
        IMulticall3 multicall3;
        LevelReserveLensMorphoOracle levelReserveLensMorphoOracle;
        IRedemption ustbRedemptionIdle;
        ISwapRouter uniswapV3Router;
    }

    struct Oracles {
        AggregatorV3Interface usdc;
        AggregatorV3Interface usdt;
        AggregatorV3Interface ustb;
        AggregatorV3Interface aUsdt;
        AggregatorV3Interface aUsdc;
        AggregatorV3Interface mNav;
        AggregatorV3Interface cappedMNav;
    }

    Config public config;
}
