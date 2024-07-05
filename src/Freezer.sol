// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStakedlvlUSD.sol";
import "./interfaces/IlvlUSD.sol";

contract Freezer {
    address immutable SLVLUSD;
    IlvlUSD immutable LVLUSD;

    event WithdrawnFromFreezer(
        address freezer,
        address to,
        address slvlusd,
        uint256 amount
    );

    error OnlySlasherOrStakingVault();

    constructor(address stakingVault, address asset) {
        LVLUSD = IlvlUSD(asset);
        SLVLUSD = stakingVault;
    }

    modifier onlySlasherOrStakingVault() {
        if (msg.sender != SLVLUSD && msg.sender != LVLUSD.slasher())
            revert OnlySlasherOrStakingVault();
        _;
    }

    function withdraw(uint256 amount) external onlySlasherOrStakingVault {
        LVLUSD.transfer(msg.sender, amount);
        emit WithdrawnFromFreezer(address(this), msg.sender, SLVLUSD, amount);
    }
}
