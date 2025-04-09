// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface ILevelMintingErrors {
    error DenyListed();
    error InvalidAmount();
    error InvalidAddress();
    error OraclePriceIsZero();
    error OracleUndefined();
    error InvalidHeartBeatValue();
    error UnsupportedAsset();
    error StillInCooldown();
    error NoPendingRedemptions();
    error MaxMintPerBlockExceeded();
    error MaxRedeemPerBlockExceeded();
    error SlippageToleranceExceeded();
    error ExceedsMaxBlockLimit();
}
