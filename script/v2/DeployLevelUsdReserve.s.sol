// Copied from contracts-v2gi
// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity 0.8.21;

// import {
//     DeployArcticArchitecture,
//     ERC20,
//     Deployer
// } from "@boring-vault/script/ArchitectureDeployments/DeployArcticArchitecture.sol";
// import {AddressToBytes32Lib} from "@boring-vault/src/helper/AddressToBytes32Lib.sol";

// // Import Decoder and Sanitizer to deploy.
// import {EtherFiLiquidUsdDecoderAndSanitizer} from
//     "@boring-vault/src/base/DecodersAndSanitizers/EtherFiLiquidUsdDecoderAndSanitizer.sol";

// import {ContractAddresses} from "@level/config/ContractAddresses.sol";
// import {ContractNames} from "@level/config/ContractNames.sol";
// import {DeploymentUtils} from "@level/script/DeploymentUtils.sol";

// /**
//  *  source .env && forge script script/v2/DeployLevelUsdReserves.s.sol:DeployLevelUsdReserves --with-gas-price 10000000000 --slow --broadcast --etherscan-api-key $ETHERSCAN_KEY --verify
//  * @dev Optionally can change `--with-gas-price` to something more reasonable
//  */
// contract DeployLevelUsdReserve is DeploymentUtils, DeployArcticArchitecture, ContractAddresses, ContractNames {
//     using AddressToBytes32Lib for address;

//     uint256 public chainId;

//     uint256 public privateKey;

//     // Deployment parameters
//     string public boringVaultName = "Level USD Reserve";
//     string public boringVaultSymbol = "lvlUSDReserve";
//     uint8 public boringVaultDecimals = 6;
//     address public owner = dev0Address;

//     function setUp() external {
//         chainId = vm.envUint("CHAIN_ID");
//         _initializeAddresses(chainId);

//         privateKey = _getPrivateKey(chainId);
//     }

//     function run() external {
//         // Configure the deployment.
//         configureDeployment.deployContracts = true;
//         configureDeployment.setupRoles = true;
//         configureDeployment.setupDepositAssets = true;
//         configureDeployment.setupWithdrawAssets = true;
//         configureDeployment.finishSetup = true;
//         configureDeployment.setupTestUser = true;
//         configureDeployment.saveDeploymentDetails = true;
//         configureDeployment.deployerAddress = deployerAddress;
//         configureDeployment.balancerVault = balancerVault;
//         configureDeployment.WETH = address(WETH);

//         // Save deployer.
//         deployer = Deployer(configureDeployment.deployerAddress);

//         // Define names to determine where contracts are deployed.
//         names.rolesAuthority = LevelUSDReserveRolesAuthorityName;
//         names.lens = ArcticArchitectureLensName;
//         names.boringVault = LevelUSDReserveName;
//         names.manager = LevelUSDReserveManagerName;
//         names.accountant = LevelUSDReserveAccountantName;
//         names.teller = LevelUSDReserveTellerName;
//         names.rawDataDecoderAndSanitizer = LevelUSDReserveDecoderAndSanitizerName;
//         names.delayedWithdrawer = LevelUSDReserveDelayedWithdrawer;

//         // Define Accountant Parameters.
//         accountantParameters.payoutAddress = liquidPayoutAddress;
//         accountantParameters.base = USDC;
//         // Decimals are in terms of `base`.
//         accountantParameters.startingExchangeRate = 1e6;
//         //  4 decimals
//         accountantParameters.managementFee = 0;
//         accountantParameters.performanceFee = 0;
//         accountantParameters.allowedExchangeRateChangeLower = 0.995e4;
//         accountantParameters.allowedExchangeRateChangeUpper = 1.005e4;
//         // Minimum time(in seconds) to pass between updated without triggering a pause.
//         accountantParameters.minimumUpateDelayInSeconds = 1 days / 4;

//         // Define Decoder and Sanitizer deployment details.
//         bytes memory creationCode = type(EtherFiLiquidUsdDecoderAndSanitizer).creationCode;
//         bytes memory constructorArgs =
//             abi.encode(deployer.getAddress(names.boringVault), uniswapV3NonFungiblePositionManager);

//         // Setup extra deposit assets.
//         // none to setup

//         // Setup withdraw assets.
//         withdrawAssets.push(
//             WithdrawAsset({
//                 asset: USDC,
//                 withdrawDelay: 3 days,
//                 completionWindow: 7 days,
//                 withdrawFee: 0,
//                 maxLoss: 0.01e4
//             })
//         );

//         withdrawAssets.push(
//             WithdrawAsset({
//                 asset: USDT,
//                 withdrawDelay: 3 days,
//                 completionWindow: 7 days,
//                 withdrawFee: 0,
//                 maxLoss: 0.01e4
//             })
//         );

//         bool allowPublicDeposits = false;
//         bool allowPublicWithdraws = false;
//         uint64 shareLockPeriod = 1 days;
//         address delayedWithdrawFeeAddress = liquidPayoutAddress;

//         vm.startBroadcast(privateKey);

//         _deploy(
//             "LevelUsdReserveDeployment.json",
//             owner,
//             boringVaultName,
//             boringVaultSymbol,
//             boringVaultDecimals,
//             creationCode,
//             constructorArgs,
//             delayedWithdrawFeeAddress,
//             allowPublicDeposits,
//             allowPublicWithdraws,
//             shareLockPeriod,
//             dev1Address
//         );

//         vm.stopBroadcast();
//     }
// }
