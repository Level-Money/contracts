// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC4626 is ERC4626 {
    uint256 private _convertToAssetsOutput;

    constructor(IERC20 _underlying) ERC4626(_underlying) ERC20("Mock", "MOCK") {}

    function setConvertToAssetsOutput(uint256 output) external {
        _convertToAssetsOutput = output;
    }

    function convertToAssets(uint256 /* shares */ ) public view override returns (uint256) {
        return _convertToAssetsOutput;
    }
}
