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
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IMetaMorpho} from "@level/src/v2/interfaces/morpho/IMetaMorpho.sol";
import {IMetaMorphoV1_1} from "@level/src/v2/interfaces/morpho/IMetaMorphoV1_1.sol";

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {RewardsManager} from "@level/src/v2/usd/RewardsManager.sol";
import {PauserGuard} from "@level/src/v2/common/guard/PauserGuard.sol";
import {StrictRolesAuthority} from "@level/src/v2/auth/StrictRolesAuthority.sol";

import {LevelReserveLens} from "@level/src/v2/lens/LevelReserveLens.sol";
import {LevelReserveLensMorphoOracle} from "@level/src/v1/lens/LevelReserveLensMorphoOracle.sol";
import {IRedemption} from "@level/src/v2/interfaces/superstate/IRedemption.sol";
import {ISwapRouter} from "@level/src/v2/interfaces/uniswap/ISwapRouter.sol";
import {SwapManager} from "@level/src/v2/usd/SwapManager.sol";

contract Sepolia is BaseConfig {
    uint256 public constant chainId = 11155111;

    function initialize() public returns (BaseConfig.Config memory) {
        address[] memory hexagateGatekeepers = new address[](1);
        hexagateGatekeepers[0] = 0xb2522DC238DEA8a821dEcE38a1d46eC5C4708256;

        config = BaseConfig.Config({
            chainId: chainId,
            tokens: Tokens({
                usdc: ERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238),
                usdt: ERC20(address(0)),
                lvlUsd: ERC20(0xd770C092e4AcA4Cdb187829C350062C43F6f79EB),
                slvlUsd: ERC20(0xeFE4aB4013beca790A957e12330C7283AB97a047),
                aUsdc: ERC20(address(0)),
                aUsdt: ERC20(address(0)),
                ustb: ERC20(0x39727692cF58137Bd8c401eFE87Cc8A190D62ead),
                wrappedM: ERC20(address(0))
            }),
            oracles: Oracles({
                usdc: AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E),
                usdt: AggregatorV3Interface(address(0)),
                ustb: AggregatorV3Interface(0x732d3C7515356eAB22E3F3DcA183c5c65102d518),
                aUsdc: AggregatorV3Interface(address(0)),
                aUsdt: AggregatorV3Interface(address(0)),
                mNav: AggregatorV3Interface(address(0)),
                cappedMNav: AggregatorV3Interface(address(0))
            }),
            users: Users({
                admin: 0xb2522DC238DEA8a821dEcE38a1d46eC5C4708256,
                deployer: 0xb2522DC238DEA8a821dEcE38a1d46eC5C4708256,
                operator: 0xb2522DC238DEA8a821dEcE38a1d46eC5C4708256,
                protocolTreasury: 0xb2522DC238DEA8a821dEcE38a1d46eC5C4708256,
                hexagateGatekeepers: hexagateGatekeepers
            }),
            levelContracts: LevelContracts({
                rolesAuthority: StrictRolesAuthority(0x5E330Aac91c21d6F4Ef60Ade3a4fCF848190b75F),
                levelMintingV2: LevelMintingV2(0x5bc5B63b7715078383A9c8565fEF69f130CcD875),
                boringVault: BoringVault(payable(0x5d47Fc00F4E6F1b8Bb77f9e9D4546857eb08dB53)),
                vaultManager: VaultManager(0x0fB3C382CA642Deb64a4B9249303E368C164c267),
                rewardsManager: RewardsManager(0x084D870E5E418D6c875d360187c7Fd4fBc2Af934),
                adminTimelock: TimelockController(payable(0x980bF41Dc21fA48BE87a421002c18a6c803d480C)),
                erc4626OracleFactory: ERC4626OracleFactory(0xe9D32Aade0228A8de8E54b48b8020DA2907449fb),
                pauserGuard: PauserGuard(0xABf29A4a281f6ea06883DedeA962127f9b0621f9),
                levelReserveLens: LevelReserveLens(address(0)),
                swapManager: SwapManager(address(0))
            }),
            morphoVaults: MorphoVaults({
                steakhouseUsdc: MetaMorphoVault({
                    vault: IMetaMorpho(0x844DCaAE589F8a3CaDE4F1eAD154499ce8A07F75),
                    oracle: IERC4626Oracle(address(0))
                }),
                steakhouseUsdt: MetaMorphoVault({vault: IMetaMorpho(address(0)), oracle: IERC4626Oracle(address(0))}),
                re7Usdc: MetaMorphoV1_1Vault({vault: IMetaMorphoV1_1(address(0)), oracle: IERC4626Oracle(address(0))}),
                steakhouseUsdtLite: MetaMorphoV1_1Vault({vault: IMetaMorphoV1_1(address(0)), oracle: IERC4626Oracle(address(0))})
            }),
            sparkVaults: SparkVaults({
                sUsdc: ERC4626Vault({vault: IERC4626(address(0)), oracle: IERC4626Oracle(address(0))})
            }),
            umbrellaVaults: UmbrellaVaults({
                waUsdcStakeToken: ERC4626Vault({vault: IERC4626(address(0)), oracle: IERC4626Oracle(address(0))}),
                waUsdtStakeToken: ERC4626Vault({vault: IERC4626(address(0)), oracle: IERC4626Oracle(address(0))})
            }),
            periphery: PeripheryContracts({
                aaveV3: IPool(0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951),
                multicall3: IMulticall3(0xcA11bde05977b3631167028862bE2a173976CA11),
                levelReserveLensMorphoOracle: LevelReserveLensMorphoOracle(address(0)),
                ustbRedemptionIdle: IRedemption(0xd33d340CdbEf8E879C827199BD7D9705b21e18c9),
                uniswapV3Router: ISwapRouter(address(0))
            })
        });

        return config;
    }
}
