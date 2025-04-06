// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ILevelMintingV2} from "@level/src/v2/interfaces/ILevelMintingV2.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {VaultManager} from "@level/src/v2/usd/VaultManager.sol";
import {Silo} from "@level/src/v2/usd/Silo.sol";
import {IlvlUSD} from "@level/src/v2/interfaces/IlvlUSD.sol";

abstract contract LevelMintingV2Storage is ILevelMintingV2 {
    /* --------------- GLOBAL VARIABLES --------------- */
    VaultManager public vaultManager;
    Silo public silo;

    mapping(address => bool) public mintableAssets;
    mapping(address => bool) public redeemableAssets;

    mapping(address user => mapping(address asset => uint256 cooldown)) public userCooldown;
    uint256 public cooldownDuration;

    /// @notice lvlUSD minted per block
    mapping(uint256 => uint256) public mintedPerBlock;
    /// @notice asset redeemed per block
    mapping(uint256 => uint256) public redeemedPerBlock;

    /// @notice max minted lvlUSD allowed per block
    uint256 public maxMintPerBlock;
    /// @notice max redeemed collateral allowed per block
    uint256 public maxRedeemPerBlock;

    mapping(address => mapping(address => uint256)) public pendingRedemption;

    mapping(address => address) public oracles;
    mapping(address => uint256) public heartbeats;

    mapping(address => bool) public isLevelOracle;

    /// @notice lvlusd stablecoin
    IlvlUSD public constant lvlusd = IlvlUSD(0x7C1156E515aA1A2E851674120074968C905aAF37);
    uint8 public constant LVLUSD_DECIMAL = 18;

    constructor() {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
