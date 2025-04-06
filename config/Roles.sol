// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

// Roles used in RolesAuthority for v2
contract Roles {
    uint8 public constant ADMIN_MULTISIG_ROLE = 1;
    uint8 public constant VAULT_MINTER_ROLE = 2;
    uint8 public constant VAULT_REDEEMER_ROLE = 3;
    uint8 public constant PAUSER_ROLE = 4;
    uint8 public constant UNPAUSER_ROLE = 5;
    uint8 public constant VAULT_MANAGER_ROLE = 6;
    uint8 public constant GATEKEEPER_ROLE = 7;
    uint8 public constant TRANSFER_ALLOWLISTER_ROLE = 8;
    uint8 public constant REWARDER_ROLE = 9;
    uint8 public constant DEPLOYER_ROLE = 10;
    uint8 public constant STRATEGIST_ROLE = 11;
    uint8 public constant MINTER_ROLE = 12;
    uint8 public constant REDEEMER_ROLE = 13;
    uint8 public constant INSTANT_REDEEMER_ROLE = 14;
}
