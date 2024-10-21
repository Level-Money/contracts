// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./LevelBaseReserveManager.sol";
import "../interfaces/IDelegationManager.sol";
import "../interfaces/ISignatureUtils.sol";

/**
 * @title Level Reserve Manager
 */
contract EigenlayerReserveManager is LevelBaseReserveManager {
    using SafeERC20 for IERC20;

    address public delegationManager;

    event Undelegated();
    event DelegatedToOperator(address operator);

    /* --------------- CONSTRUCTOR --------------- */

    constructor(
        IlvlUSD _lvlusd,
        address _delegationManager,
        IStakedlvlUSD _stakedlvlUSD,
        address _admin,
        address _allowlister
    ) LevelBaseReserveManager(_lvlusd, _stakedlvlUSD, _admin, _allowlister) {
        delegationManager = _delegationManager;
    }

    /* --------------- EXTERNAL --------------- */

    function delegateTo(
        address operator,
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused {
        IDelegationManager(delegationManager).delegateTo(
            operator,
            approverSignatureAndExpiry,
            approverSalt
        );
        emit DelegatedToOperator(operator);
    }

    function undelegate() external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused {
        IDelegationManager(delegationManager).undelegate(address(this));
        emit Undelegated();
    }

    function queueWithdrawals(
        IDelegationManager.QueuedWithdrawalParams[]
            calldata queuedWithdrawalParams
    )
        external
        onlyRole(MANAGER_AGENT_ROLE)
        whenNotPaused
        returns (bytes32[] memory)
    {
        return
            IDelegationManager(delegationManager).queueWithdrawals(
                queuedWithdrawalParams
            );
    }

    function completeQueuedWithdrawal(
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused {
        IDelegationManager(delegationManager).completeQueuedWithdrawal(
            withdrawal,
            tokens,
            middlewareTimesIndex,
            receiveAsTokens
        );
    }
}
