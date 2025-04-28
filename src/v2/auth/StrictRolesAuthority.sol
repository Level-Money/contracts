// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {RolesAuthority} from "@solmate/src/auth/authorities/RolesAuthority.sol";
import {Authority} from "@solmate/src/auth/Auth.sol";

/**
 * @title StrictRolesAuthority
 * @notice An extension of RolesAuthority that enforces stricter role management rules
 * @dev This contract only allows adding roles through setUserRole() and requires admin multisig
 *      approval for role removal through removeUserRole()
 */
contract StrictRolesAuthority is RolesAuthority {
    /// @notice The error emitted when a user attempts to remove a role
    error RoleRemovalNotAllowed();

    /// @notice Emitted when a role is configured as removable
    event RemovableRoleConfigured(uint8 indexed role, bool allowed);

    /// @notice Which roles are allowed to be removed
    mapping(uint8 => bool) public isRoleRemovable;

    /**
     * @notice Creates a new StrictRolesAuthority instance
     * @param _owner The address that will be the owner of this authority
     * @param _authority The authority contract to use for authentication
     */
    constructor(address _owner, Authority _authority) RolesAuthority(_owner, _authority) {}

    /**
     * @notice Sets a role for a user, but only allows adding roles
     * @dev This function can only be called by authorized addresses
     * @param user The address of the user to set the role for
     * @param role The role to set
     * @param enabled Must be true, as this function only allows adding roles
     * @custom:reverts If enabled is false or caller is not authorized
     */
    function setUserRole(address user, uint8 role, bool enabled) public virtual override requiresAuth {
        if (!enabled) {
            revert RoleRemovalNotAllowed();
        }

        getUserRoles[user] |= bytes32(1 << role);

        emit UserRoleUpdated(user, role, true);
    }

    /**
     * @notice Removes a role from a user
     * @dev This function can only be called by called by the ADMIN_MULTISIG_ROLE
     * @param user The address of the user to remove the role from
     * @param role The role to remove
     * @custom:reverts If caller is not the admin multisig
     */
    function removeUserRole(address user, uint8 role) external virtual requiresAuth {
        if (!isRoleRemovable[role]) {
            revert RoleRemovalNotAllowed();
        }

        getUserRoles[user] &= ~bytes32(1 << role);

        emit UserRoleUpdated(user, role, false);
    }

    /**
     * @notice Returns all roles for a user
     * @param user The address of the user to get the roles for
     * @return A bitmask of all roles for the user
     */
    function getAllRoles(address user) public view returns (uint256) {
        return uint256(getUserRoles[user]);
    }

    /**
     * @notice Sets a role as removable or not
     * @dev This function can only be called by the owner (timelock)
     * @param role The role to set as removable
     * @param allowed Whether the role should be removable
     * @custom:reverts If caller is not the owner
     */
    function setRoleRemovable(uint8 role, bool allowed) external requiresAuth {
        isRoleRemovable[role] = allowed;
        emit RemovableRoleConfigured(role, allowed);
    }
}
