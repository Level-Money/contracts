// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import {BaseConfig} from "@level/config/deploy/BaseConfig.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IPool} from "@level/src/v2/interfaces/aave/IPool.sol";
import {ERC4626OracleFactory} from "@level/src/v2/oracles/ERC4626OracleFactory.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {IMetaMorpho} from "@level/src/v2/interfaces/morpho/IMetaMorpho.sol";
import {IMetaMorphoV1_1} from "@level/src/v2/interfaces/morpho/IMetaMorphoV1_1.sol";

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";
import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";
import {StrictRolesAuthority} from "@level/src/v2/auth/StrictRolesAuthority.sol";
import {LevelReserveLens} from "@level/src/v2/lens/LevelReserveLens.sol";
import {LevelReserveLensMorphoOracle} from "@level/src/v1/lens/LevelReserveLensMorphoOracle.sol";

contract Mainnet is BaseConfig {
    uint256 public constant chainId = 1;

    function initialize() public returns (BaseConfig.Config memory) {
        address[] memory hexagateGatekeepers = new address[](2);
        hexagateGatekeepers[0] = 0xA7367eCE6AeA6EA5D775867Aa9B56F5f35B202Fe;
        hexagateGatekeepers[1] = 0x1557C8a68110D17cf19Bd7451972ea954B689ed6;

        config = BaseConfig.Config({
            chainId: chainId,
            tokens: Tokens({
                usdc: ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
                usdt: ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7),
                lvlUsd: ERC20(0x7C1156E515aA1A2E851674120074968C905aAF37),
                slvlUsd: ERC20(0x4737D9b4592B40d51e110b94c9C043c6654067Ae),
                aUsdc: ERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c),
                aUsdt: ERC20(0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a)
            }),
            oracles: Oracles({
                usdc: AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6),
                usdt: AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D),
                ustb: AggregatorV3Interface(0x289B5036cd942e619E1Ee48670F98d214E745AAC)
            }),
            users: Users({
                admin: 0x343ACce723339D5A417411D8Ff57fde8886E91dc,
                deployer: 0x5b5004f1bC12C66F94782070032a6eAdC6821a3e,
                operator: 0xcEa14C3e9Afc5822d44ADe8d006fCFBAb60f7a21,
                protocolTreasury: 0xDf95bb71581B224BD42eB19ceaff5E92816e181E,
                hexagateGatekeepers: hexagateGatekeepers
            }),
            levelContracts: LevelContracts({
                rolesAuthority: StrictRolesAuthority(address(0)),
                levelMintingV2: LevelMintingV2(address(0)),
                boringVault: BoringVault(payable(address(0))),
                vaultManager: VaultManager(address(0)),
                rewardsManager: RewardsManager(address(0)),
                adminTimelock: TimelockController(payable(0x0798880E772009DDf6eF062F2Ef32c738119d086)),
                erc4626OracleFactory: ERC4626OracleFactory(address(0)),
                pauserGuard: PauserGuard(address(0)),
                levelReserveLens: LevelReserveLens(0x29759944834e08acE755dcEA71491413f7e2CBAD)
            }),
            morphoVaults: MorphoVaults({
                steakhouseUsdc: MetaMorphoVault({
                    vault: IMetaMorpho(0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB),
                    oracle: IERC4626Oracle(address(0))
                }),
                steakhouseUsdt: MetaMorphoVault({
                    vault: IMetaMorpho(0xbEef047a543E45807105E51A8BBEFCc5950fcfBa),
                    oracle: IERC4626Oracle(address(0))
                }),
                re7Usdc: MetaMorphoV1_1Vault({
                    vault: IMetaMorphoV1_1(0x64964E162Aa18d32f91eA5B24a09529f811AEB8e),
                    oracle: IERC4626Oracle(address(0))
                }),
                steakhouseUsdtLite: MetaMorphoV1_1Vault({
                    vault: IMetaMorphoV1_1(0x097FFEDb80d4b2Ca6105a07a4D90eB739C45A666),
                    oracle: IERC4626Oracle(address(0))
                })
            }),
            periphery: PeripheryContracts({
                aaveV3: IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2),
                multicall3: IMulticall3(0xcA11bde05977b3631167028862bE2a173976CA11),
                levelReserveLensMorphoOracle: LevelReserveLensMorphoOracle(0x625bB4f5133Ff9F6d43e21F15add35BE46387903)
            })
        });

        return config;
    }
}
