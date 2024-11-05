// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./LevelBaseReserveManager.sol";
import "../interfaces/eigenlayer/IDelegationManager.sol";
import "../interfaces/eigenlayer/IStrategyManager.sol";
import "../interfaces/eigenlayer/ISignatureUtils.sol";
import "../interfaces/eigenlayer/IRewardsCoordinator.sol";

/**
 * @title Level Reserve Manager
 */
contract EigenlayerReserveManager is LevelBaseReserveManager {
    using SafeERC20 for IERC20;

    address public delegationManager;
    address public strategyManager;
    address public rewardsCoordinator;
    string public operatorName;

    error StrategiesAndSharesMustBeSameLength();
    error StrategiesSharesAndTokensMustBeSameLength();

    event Undelegated();
    event DelegatedToOperator(address operator);

    /* --------------- CONSTRUCTOR --------------- */

    constructor(
        IlvlUSD _lvlusd,
        address _delegationManager,
        address _strategyManager,
        address _rewardsCoordinator,
        IStakedlvlUSD _stakedlvlUSD,
        address _admin,
        address _allowlister,
        string memory _operatorName
    ) LevelBaseReserveManager(_lvlusd, _stakedlvlUSD, _admin, _allowlister) {
        delegationManager = _delegationManager;
        strategyManager = _strategyManager;
        rewardsCoordinator = _rewardsCoordinator;
        operatorName = _operatorName;
    }

    // note Delvir0 setting this in the specific reserve managers as each is different 
    mapping (address benefactor => bytes32[] queuAnswer) public withdrawalKeys;

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
        tokenContract.forceApprove(address(strategyManager), amount);

        // Deposit into the strategy
        IStrategyManager(strategyManager).depositIntoStrategy( 
            IStrategy(strategy),
            tokenContract,
            amount
        );
    }

    // note Delvir0 connects keys to benefactor in order to finish redeem 
    // current only supports single entry
    // !important! assuming that there is 1 strategy address per token address (e.g. USDC => address strategyUSDC and USDT => address strategyUSDT )
    function initiateGlobalRedeem(address benefactor, address asset, uint256 withdrawalAmount) external onlyRole(LEVEL_MINTING) whenNotPaused {
        // note Delvir0 used to fetch and store answer to use later at completeQueuedWithdrawal
        // TODO !important! need to change withdrawalAmount to shares as each deposited amount equals to a sepcific amount of shares
        // for this to work, deposit needs to store amount of shares for each user
        bytes32[] withdrawalParamAnswer = queueWithdrawals(assetToStrategy.asset, withdrawalAmount); 
        withdrawalKeys[benefactor].push(withdrawalParamAnswer[0]);
    }

    function completeGlobalRedeem(address benefactor) external onlyRole(LEVEL_MINTING) whenNotPaused {
        completeQueuedWithdrawal(benefactor);
    }

    // note Delvir0 current only supports single entry
    function queueWithdrawals(
        address _strategy,
        uint256 _shares
    )
        external
        onlyRole(MANAGER_AGENT_ROLE) // TODO Delvir0 this would need to be set to also allow LevelMinting contract
        whenNotPaused
        returns (bytes32[] memory)
    {

        if (strategies.length != shares.length) {
            revert StrategiesAndSharesMustBeSameLength();
        }

        // Delvir0 sorry for making your eyes bleed with this
        IDelegationManager.IStrategy[] memory strategy = [_strategy];
        uint256[] shares = [_shares];
    
        IDelegationManager.QueuedWithdrawalParams memory withdrawalParam = IDelegationManager
            .QueuedWithdrawalParams({
                strategies: strategy, // Array of strategies that the QueuedWithdrawal contains
                shares: shares, // Array containing the amount of shares in each Strategy in the `strategies` array
                withdrawer: address(this) // The address of the withdrawer
            });
        IDelegationManager.QueuedWithdrawalParams[]
            memory withdrawalParams = new IDelegationManager.QueuedWithdrawalParams[](
                1
            );
        withdrawalParams[0] = withdrawalParam;
        
        return
            IDelegationManager(delegationManager).queueWithdrawals(
                withdrawalParams
            );
    }

    // The arguments to the functions (specifically nonce and startBlock)
    // can be found by fetching the relevant event emitted by queueWithdrawal or undelegate:
    //
    // - WithdrawalQueued(bytes32 withdrawalRoot, Withdrawal withdrawal)
    //
    // For reference, the Withdrawal struct looks like:
    //
    //  struct Withdrawal {
    //    address staker;
    //    address delegatedTo;
    //    address withdrawer;
    //    uint256 nonce;
    //    uint32 startBlock;
    //    IStrategy[] strategies;
    //    uint256[] shares;
    //   }
    //
    // Note that multiple withdraw requests can be queued at once.
    function completeQueuedWithdrawal(
        address benefactor
    ) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused { // TODO Delvir0 this would need to be set to also allow LevelMinting contract
        
        IDelegationManager.Withdrawal memory withdrawal; 

        for (uint256 i = 0; i < withdrawalKeys[benefactor].length; i++) { 

            // note Delvir0 params should be same as input so removing assigning staker and withdrawer to address(this)
            (
                withdrawal.staker,
                withdrawal.delegatedTo,
                withdrawal.withdrawer,
                withdrawal.nonce,
                withdrawal.startBlock,
                withdrawal.strategies,
                withdrawal.shares
            ) = abi.decode(withdrawalKeys[benefactor][i], (address,address,address,uint256,uint32,IDelegationManager.IStrategy[],uint256[]));
        
            IDelegationManager(delegationManager).completeQueuedWithdrawal(
                withdrawal,
                token, //TODO Delvir0 this is waUSDC/T which is tied to waUSDC/T strategy. We need to perform a lookup on the token address behind this strategy or add an inverse assetToStrategy mapping
                0 /* middleware index is currently a no-op */,
                true /* receive as tokens*/
            );

            yieldManager[token].withdraw(token, amount); //TODO same as TODO above, we need to specify the wrapped token
            IERC20[token].safeTransfer(address(withdrawal.withdrawer));
        }

        delete withdrawalKeys[benefactor];
    }

    // sets the rewards claimer for this contract to be `claimer`
    function setRewardsClaimer(
        address claimer
    ) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused {
        IRewardsCoordinator(rewardsCoordinator).setClaimerFor(claimer);
    }

    // ============================== SETTERS ==============================

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

    function setRewardsCoordinator(
        address _rewardsCoordinator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsCoordinator = _rewardsCoordinator;
    }

    function setOperatorName(
        string calldata _operatorName
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorName = _operatorName;
    }
}
