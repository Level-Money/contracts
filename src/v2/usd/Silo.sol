// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

contract Silo {
    using SafeTransferLib for ERC20;

    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /// @notice only callable by LevelMintingV2
    function withdraw(address beneficiary, address asset, uint256 amount) external {
        require(asset.code.length != 0, "Token does not exist");
        ERC20(asset).safeTransfer(beneficiary, amount);
    }
}
