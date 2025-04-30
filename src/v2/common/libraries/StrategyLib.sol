// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {OracleLib} from "@level/src/v2/common/libraries/OracleLib.sol";

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

/// @title StrategyLib
/// @author Level (https://level.money)
/// @notice Library to get values stored in strategies
library StrategyLib {
    using MathLib for uint256;

    /// @notice Error thrown when a strategy is invalid
    error InvalidStrategy();

    /// @notice Returns the total assets of the given strategies
    /// @param configs The strategy configs. Reverts if the strategies have different base collateral
    /// @param vault The vault address
    /// @return assets_ The total assets of the given strategies, denominated in the common base collateral
    function getAssets(StrategyConfig[] memory configs, address vault) internal view returns (uint256 assets_) {
        address baseCollateral;
        if (configs.length > 0) {
            baseCollateral = address(configs[0].baseCollateral);
        }

        for (uint256 i = 0; i < configs.length; i++) {
            if (baseCollateral != address(configs[i].baseCollateral)) {
                revert InvalidStrategy();
            }
            assets_ += getAssets(configs[i], vault);
        }

        return assets_;
    }

    /// @notice Returns the total assets of the given strategy
    /// @param config The strategy config
    /// @param vault The vault address
    /// @return assets_ The total assets of the given strategy, denominated in the strategy's base collateral
    function getAssets(StrategyConfig memory config, address vault) internal view returns (uint256 assets_) {
        IERC20Metadata receiptToken = IERC20Metadata(address(config.receiptToken));

        if (address(receiptToken) == address(0)) {
            revert InvalidStrategy();
        }

        uint256 shares = receiptToken.balanceOf(vault);

        (int256 assetsForOneShare, uint256 oracleDecimals) =
            OracleLib.getPriceAndDecimals(address(config.oracle), config.heartbeat);

        assets_ = uint256(assetsForOneShare).mulDivDown(shares, 10 ** receiptToken.decimals());

        return assets_.convertDecimalsDown(uint8(oracleDecimals), config.baseCollateral.decimals());
    }

    /// @notice Validate a strategy configuration
    /// @param config The strategy configuration to validate
    /// @param baseCollateral The base collateral of the strategy
    /// @dev Reverts with InvalidStrategy if the strategy is invalid
    function validateStrategy(StrategyConfig memory config, address baseCollateral) internal pure {
        if (address(config.baseCollateral) != baseCollateral) {
            revert InvalidStrategy();
        }

        if (config.category == StrategyCategory.UNDEFINED) {
            revert InvalidStrategy();
        }
    }
}
