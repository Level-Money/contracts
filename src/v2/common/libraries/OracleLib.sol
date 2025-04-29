// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";

/// @title OracleLib
/// @author Level (https://level.money)
/// @notice Library to manage oracle operations
library OracleLib {
    function getPriceAndDecimals(address oracle, uint256 heartBeat)
        internal
        view
        returns (int256 price, uint256 decimal)
    {
        uint8 decimals = AggregatorV3Interface(oracle).decimals();
        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();

        if (answer == 0) {
            revert("OracleLib: Invalid price");
        }

        if (block.timestamp > updatedAt + heartBeat) {
            revert("OracleLib: Stale price");
        }

        return (answer, decimals);
    }

    function _tryUpdateOracle(address _oracle) internal returns (bool isSuccess) {
        IERC4626Oracle oracle = IERC4626Oracle(_oracle);

        try oracle.update() {
            return true;
        } catch {
            return false;
        }
    }
}
