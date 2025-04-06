// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Auth, Authority} from "@solmate/src/auth/Auth.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

interface IRewardsManager {
    function initialize(address admin_, address vault_) external;
    function setVault(address vault_) external;
    function setTreasury(address treasury_) external;
    function reward(address[] calldata assets) external;
    function getAccruedYield(address[] calldata assets) external view returns (uint256);
}
