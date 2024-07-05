// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IslvlUSDSiloDefinitions.sol";

/**
 * @title slvlUSDSilo
 * @notice The Silo allows to store slvlUSD during the stake cooldown process.
 */
contract slvlUSDSilo is IslvlUSDSiloDefinitions {
    address immutable STAKING_VAULT;

    constructor(address stakingVault) {
        STAKING_VAULT = stakingVault;
    }

    modifier onlyStakingVault() {
        if (msg.sender != STAKING_VAULT) revert OnlyStakingVault();
        _;
    }

    function withdraw(address to, uint256 amount) external onlyStakingVault {
        IERC20(STAKING_VAULT).transfer(to, amount);
    }
}
