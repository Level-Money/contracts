// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILevelBaseYieldManager {
    function setWrapperForToken(address token, address wrapper) external;

    function approveSpender(
        address token,
        address spender,
        uint256 amount
    ) external;

    function depositForYield(address token, uint256 amount) external;

    function withdraw(address token, uint256 amount) external;

    /// @notice Treasury is the zero address
    error TreasuryNotSet();
    /// @notice Zero address error
    error ZeroAddress();
}
