// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LevelMintingV2} from "@level/src/v2/LevelMintingV2.sol";
import {ILevelMintingV2, ILevelMintingV2Structs} from "@level/src/v2/interfaces/level/ILevelMintingV2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {VaultLib} from "@level/src/v2/common/libraries/VaultLib.sol";
import {StrategyLib, StrategyConfig} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {RewardsManagerStorage} from "@level/src/v2/usd/RewardsManagerStorage.sol";
import {IRewardsManager} from "@level/src/v2/interfaces/level/IRewardsManager.sol";
import {PauserGuardedUpgradable} from "@level/src/v2/common/guard/PauserGuardedUpgradable.sol";
import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";

contract RewardsDistributor {
    using SafeERC20 for ERC20;
    using MathLib for uint256;
    using StrategyLib for StrategyConfig;
    using VaultLib for BoringVault;

    LevelMintingV2 public immutable mintingContract;
    BoringVault public immutable vault;
    IRewardsManager public immutable rewardsManager;

    constructor(address _mintingContract, address _rewardsManager) {
        mintingContract = LevelMintingV2(_mintingContract);
        vault = mintingContract.vaultManager().vault();
        rewardsManager = IRewardsManager(_rewardsManager);
    }

    function mint(ERC20 _asset) external returns (uint256) {
        uint256 balance = _asset.balanceOf(msg.sender);

        _asset.safeTransferFrom(msg.sender, address(this), balance);

        if (balance == 0) revert("InvalidAmount");

        _asset.forceApprove(address(vault), balance);
        ILevelMintingV2Structs.Order memory order = ILevelMintingV2Structs.Order({
            beneficiary: msg.sender,
            collateral_asset: address(_asset),
            collateral_amount: balance,
            min_lvlusd_amount: 0
        });
        return mintingContract.mint(order);
    }

    function getAccruedYield(address[] memory assets) public view returns (uint256 accrued) {
        uint256 total;

        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];

            StrategyConfig[] memory strategies = rewardsManager.getAllStrategies(asset);

            uint256 totalForAsset = vault._getTotalAssets(strategies, asset);

            (int256 price, uint256 decimals) = OracleLib.getPriceAndDecimals(
                RewardsManagerStorage(address(rewardsManager)).oracles(asset),
                RewardsManagerStorage(address(rewardsManager)).HEARTBEAT()
            );
            uint256 adjustedAmount;

            // Check if price is under peg
            if (uint256(price) < 10 ** decimals) {
                adjustedAmount = totalForAsset.mulDivDown(uint256(price), 10 ** decimals);
                total += adjustedAmount.convertDecimalsDown(ERC20(asset).decimals(), vault.decimals());
            } else {
                total += totalForAsset.convertDecimalsDown(ERC20(asset).decimals(), vault.decimals());
            }
        }

        uint256 vaultShares = vault.balanceOf(address(vault));

        if (total <= vaultShares) {
            // If the total is less than the vault shares, return 0
            // This can happen if the price is under peg
            return 0;
        }

        accrued = total - vaultShares;

        return accrued;
    }
}
