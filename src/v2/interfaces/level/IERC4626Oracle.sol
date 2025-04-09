// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@level/src/v2/interfaces/AggregatorV3Interface.sol";

interface IERC4626Oracle is AggregatorV3Interface {
    function update() external;
}
