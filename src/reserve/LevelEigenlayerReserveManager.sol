// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./LevelBaseReserveManager.sol";
import "../interfaces/IDelegationManager.sol";
import "../interfaces/IStrategyManager.sol";
import "../interfaces/ISignatureUtils.sol";

/**
 * @title Level Reserve Manager
 */
contract EigenlayerReserveManager is LevelBaseReserveManager {
    using SafeERC20 for IERC20;

    address public delegationManager;
    address public strategyManager;
    string public operatorName;

    event Undelegated();
    event DelegatedToOperator(address operator);

    /* --------------- CONSTRUCTOR --------------- */

    constructor(
        IlvlUSD _lvlusd,
        address _delegationManager,
        address _strategyManager,
        IStakedlvlUSD _stakedlvlUSD,
        address _admin,
        address _allowlister,
        string memory _operatorName
    ) LevelBaseReserveManager(_lvlusd, _stakedlvlUSD, _admin, _allowlister) {
        delegationManager = _delegationManager;
        strategyManager = _strategyManager;
        operatorName = _operatorName;
    }

    /* --------------- EXTERNAL --------------- */

    function delegateTo(
        address operator,
        bytes memory signature,
        uint256 expiry,
        bytes32 approverSalt
    ) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused {
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = ISignatureUtils
                .SignatureWithExpiry({signature: signature, expiry: expiry});
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

    function depositIntoStrategy(
        address strategy,
        address token,
        uint256 amount
    ) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused {
        IERC20 tokenContract = IERC20(token);

        // Approve the StrategyManager to spend the tokens
        tokenContract.approve(address(strategyManager), amount);

        // Deposit into the strategy
        IStrategyManager(strategyManager).depositIntoStrategy(
            IStrategy(strategy),
            tokenContract,
            amount
        );
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

    function setDelegationManager(
        address _delegationManager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delegationManager = _delegationManager;
    }

    function setStrategyManager(
        address _strategyManager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        strategyManager = _strategyManager;
    }

    function setOperatorName(
        string calldata _operatorName
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorName = _operatorName;
    }
}
