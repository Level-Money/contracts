// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Auth, Authority} from "@solmate/src/auth/Auth.sol";

/**
 * @title PauserGuard
 * @notice Abstract contract that provides a flexible pausing mechanism for function selectors
 * @dev This contract allows for granular control over function execution through a pausing system.
 * Functions can be paused individually or as part of a group. Groups are logical collections of
 * function selectors that can be paused/unpaused together.
 *
 * The group parameter (bytes32) is expected to be a keccak256 hash of a descriptive string
 * representing the group's purpose.
 */
contract PauserGuard is Auth {
    /// @notice Represents a function signature and its associated contract address
    struct FunctionSig {
        bytes4 selector;
        address target;
    }

    /// @notice Tracks which selectors are currently paused
    mapping(address => mapping(bytes4 => bool)) public pausedSelectors;

    /// @notice Defines logical groupings of function selectors
    mapping(bytes32 => FunctionSig[]) public groupToFunctions;

    /// @notice Tracks which selectors are configurable (pre-approved)
    mapping(address => mapping(bytes4 => bool)) public isPausableSelector;

    event SelectorPaused(address indexed target, bytes4 indexed selector, address indexed by);
    event SelectorUnpaused(address indexed target, bytes4 indexed selector, address indexed by);
    event GroupPaused(bytes32 indexed group, address indexed by);
    event GroupUnpaused(bytes32 indexed group, address indexed by);
    event FunctionSigConfigured(bytes32 indexed group, address indexed target, bytes4 selector);

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    // ============ Configuration (governance-controlled) ============

    /**
     * @notice Configures a group of function selectors that can be paused together
     * @dev This function allows the authority to define a logical group of functions
     * that can be paused/unpaused together. Once configured, all selectors in the group
     * become pausable. Only callable by authorized addresses (AdminTimelock only)
     * @param group The keccak256 hash of the group identifier (e.g., keccak256("EMERGENCY_PAUSE"))
     * @param signatures Array of function signatures and their associated contract addresses
     * to be included in the group
     * @dev Throws if signatures array is empty or exceeds 255 selectors
     */
    function configureGroup(bytes32 group, FunctionSig[] calldata signatures) external requiresAuth {
        if (signatures.length == 0) {
            revert("Selectors must not be empty");
        }
        if (signatures.length > 255) {
            revert("Selectors must not exceed 255");
        }
        groupToFunctions[group] = signatures;

        for (uint256 i = 0; i < signatures.length; i++) {
            isPausableSelector[signatures[i].target][signatures[i].selector] = true;
            emit FunctionSigConfigured(group, signatures[i].target, signatures[i].selector);
        }
    }

    // ============ Pausing ============

    /**
     * @notice Pauses a specific function selector
     * @dev Only callable by authorized addresses (must have PAUSER_ROLE)
     * @param selector The function selector to pause
     * @dev Throws if the selector is not configured as pausable
     */
    function pauseSelector(address target, bytes4 selector) external requiresAuth {
        if (!isPausableSelector[target][selector]) {
            revert("Selector not pausable");
        }
        pausedSelectors[target][selector] = true;
        emit SelectorPaused(target, selector, msg.sender);
    }

    /**
     * @notice Unpauses a specific function selector
     * @dev Only callable by authorized addresses (must have UNPAUSER_ROLE)
     * @param selector The function selector to unpause
     * @dev Throws if the selector is not currently paused
     */
    function unpauseSelector(address target, bytes4 selector) external requiresAuth {
        if (!pausedSelectors[target][selector]) {
            revert("Selector not paused");
        }
        pausedSelectors[target][selector] = false;
        emit SelectorUnpaused(target, selector, msg.sender);
    }

    /**
     * @notice Pauses all functions in a configured group
     * @dev Only callable by authorized addresses (must have PAUSER_ROLE)
     * @param group The keccak256 hash of the group identifier
     * @dev Emits events only for selectors that were actually paused
     */
    function pauseGroup(bytes32 group) external requiresAuth {
        if (groupToFunctions[group].length == 0) {
            revert("Group not found");
        }
        FunctionSig[] memory signatures = groupToFunctions[group];
        bool anyPaused = false;
        for (uint256 i = 0; i < signatures.length; i++) {
            FunctionSig memory signature = signatures[i];
            if (!pausedSelectors[signature.target][signature.selector]) {
                pausedSelectors[signature.target][signature.selector] = true;
                emit SelectorPaused(signature.target, signature.selector, msg.sender);
                anyPaused = true;
            }
        }

        if (anyPaused) {
            emit GroupPaused(group, msg.sender);
        }
    }

    /**
     * @notice Unpauses all functions in a configured group
     * @dev Only callable by authorized addresses (must have UNPAUSER_ROLE)
     * @param group The keccak256 hash of the group identifier
     * @dev Emits events only for selectors that were actually unpaused
     */
    function unpauseGroup(bytes32 group) external requiresAuth {
        if (groupToFunctions[group].length == 0) {
            revert("Group not found");
        }
        FunctionSig[] memory signatures = groupToFunctions[group];
        bool anyUnpaused = false;
        for (uint256 i = 0; i < signatures.length; i++) {
            FunctionSig memory signature = signatures[i];
            if (pausedSelectors[signature.target][signature.selector]) {
                pausedSelectors[signature.target][signature.selector] = false;
                emit SelectorUnpaused(signature.target, signature.selector, msg.sender);
                anyUnpaused = true;
            }
        }

        if (anyUnpaused) {
            emit GroupUnpaused(group, msg.sender);
        }
    }

    // ============ View Helpers ============

    /**
     * @notice Checks if a specific function selector is paused
     * @param selector The function selector to check
     * @return bool True if the selector is paused, false otherwise
     */
    function isPaused(address target, bytes4 selector) public view returns (bool) {
        return pausedSelectors[target][selector];
    }

    /**
     * @notice Retrieves all function selectors configured for a specific group
     * @param group The keccak256 hash of the group identifier
     * @return FunctionSig[] Array of function signatures in the group
     */
    function getGroupFunctions(bytes32 group) public view returns (FunctionSig[] memory) {
        return groupToFunctions[group];
    }
}
