// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";

import {console2} from "forge-std/console2.sol";
import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title StrategyLib

enum StrategyCategory {
    UNDEFINED,
    AAVEV3,
    MORPHO
}

struct StrategyConfig {
    StrategyCategory category; // The type of strategy
    ERC20 baseCollateral;
    ERC20 receiptToken; // The token received by depositing the asset into the strategy
    AggregatorV3Interface oracle; // The oracle that provides the price of each receipt token, denominated by the asset
    address depositContract;
    address withdrawContract;
    uint256 heartbeat;
}

library StrategyLib {
    using MathLib for uint256;

    function getAssets(StrategyConfig[] memory configs, address vault) internal view returns (uint256 assets_) {
        for (uint256 i = 0; i < configs.length; i++) {
            assets_ += getAssets(configs[i], vault);
        }

        return assets_;
    }

    function getAssets(StrategyConfig memory config, address vault) internal view returns (uint256 assets_) {
        IERC20Metadata receiptToken = IERC20Metadata(address(config.receiptToken));

        if (address(receiptToken) == address(0)) {
            revert("StrategyLib: invalid strategy");
        }

        uint256 shares = receiptToken.balanceOf(vault);

        uint256 sharesToAssetDecimals =
            shares.mulDivDown(10 ** ERC20(address(config.baseCollateral)).decimals(), 10 ** receiptToken.decimals());

        (int256 assetsForOneShare, uint256 decimals) =
            OracleLib.getPriceAndDecimals(address(config.oracle), config.heartbeat);

        assets_ = uint256(assetsForOneShare).mulDivDown(sharesToAssetDecimals, 10 ** decimals);

        return assets_;
    }
}
