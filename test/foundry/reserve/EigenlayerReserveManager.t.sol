// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {EigenlayerReserveManager} from "../../../src/reserve/LevelEigenlayerReserveManager.sol";

import {IlvlUSD} from "../../../src/interfaces/IlvlUSD.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../src/interfaces/eigenlayer/IStrategyFactory.sol";
import "../../../src/interfaces/eigenlayer/IStrategy.sol";
import "../../../src/interfaces/eigenlayer/IDelegationManager.sol";
import "../../../src/interfaces/eigenlayer/IStrategyManager.sol";
import "./ReserveBaseSetup.sol";

contract EigenlayerReserveManagerTest is Test, ReserveBaseSetup {
    EigenlayerReserveManager internal eigReserveManager;

    address public constant HOLESKY_DELEGATION_MANAGER =
        0xA44151489861Fe9e3055d95adC98FbD462B948e7;

    address public constant HOLESKY_STRATEGY_MANAGER =
        0xdfB5f6CE42aAA7830E94ECFCcAd411beF4d4D5b6;

    address public constant HOLESKY_REWARDS_COORDINATOR =
        0xAcc1fb458a1317E886dB376Fc8141540537E68fE;

    address public constant HOLESKY_STRATEGY_FACTORY =
        0x9c01252B580efD11a05C00Aa42Dd3ac1Ec52DF6d;

    address public constant HOLESKY_EIGENLAYER_OPERATOR =
        0x0Ad1b51C1dCB4B16790048134ebA3207F0DA448e;

    address public constant HOLESKY_EIGENLAYER_UNREGISTERED_OPERATOR =
        address(0x123456787);

    uint256 public constant INITIAL_BALANCE = 1000000000000000000;

    uint32 public constant BLOCK_NUMBER = 2579219;

    // Delegation signer
    uint256 delegationSignerPrivateKey =
        uint256(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );
    uint256 stakerPrivateKey = uint256(123_456_789);
    address defaultApprover = vm.addr(delegationSignerPrivateKey);

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        eigReserveManager = new EigenlayerReserveManager(
            IlvlUSD(address(lvlusdToken)),
            address(0),
            address(0),
            address(0),
            stakedlvlUSD,
            address(owner),
            address(owner),
            "operator1"
        );
        _setupReserveManager(eigReserveManager);

        // Setup forked environment.
        string memory rpcKey = "HOLESKY_RPC_URL";
        uint256 blockNumber = BLOCK_NUMBER;

        utils.startFork(rpcKey, blockNumber);
        vm.warp(block.timestamp);

        vm.startPrank(owner);

        USDCToken.mint(INITIAL_BALANCE, address(eigReserveManager));
        DAIToken.mint(INITIAL_BALANCE, address(eigReserveManager));

        eigReserveManager.approveSpender(
            address(USDCToken),
            HOLESKY_STRATEGY_MANAGER,
            type(uint256).max
        );
        eigReserveManager.approveSpender(
            address(DAIToken),
            HOLESKY_STRATEGY_MANAGER,
            type(uint256).max
        );
    }

    // =====================================================================
    // =============================== TESTS ===============================
    // =====================================================================

    function test__usdc__depositDelegateWithdraw(uint256 depositAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _createEigenlayerStrategyDepositAndDelegate(USDCToken, depositAmount);
    }

    function test__usdc__depositFailsUnauthorized(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _eigenlayerDepositFailsUnauthorized(USDCToken, depositAmount);
    }

    function test__usdc__depositIntoStrategy(uint256 depositAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _testEigenlayerDepositIntoStrategy(USDCToken, depositAmount);
    }

    function test__usdc___withdrawWithoutUndelegate(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _eigenlayerWithdrawWithoutUndelegate(USDCToken, depositAmount);
    }

    function test__usdc__delegateToOperatorRequiringSignature(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _delegateToOperatorRequiringSignature(USDCToken, depositAmount);
    }

    function test__usdc__eigenlayerQueueAndCompleteMultipleWithdrawals(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _eigenlayerQueueAndCompleteMultipleWithdrawals(
            USDCToken,
            depositAmount
        );
    }

    function test__usdc__delegateToOperatorRequiringSignaturerRevertsWrongSignature(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _delegateToOperatorRequiringSignatureRevertsWrongSignature(
            USDCToken,
            depositAmount
        );
    }

    function test__usdc__depositDelegateSlashAndWithdraw(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _depositDelegateSlashAndWithdraw(USDCToken, depositAmount);
    }

    function test__usdc__depositDelegateSlashAndWithdrawRevertsInsufficientShares(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _depositDelegateSlashAndWithdrawRevertsInsufficientShares(
            USDCToken,
            depositAmount
        );
    }

    function test__dai__depositDelegateWithdraw(uint256 depositAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _createEigenlayerStrategyDepositAndDelegate(DAIToken, depositAmount);
    }

    function test__dai__depositFailsUnauthorized(uint256 depositAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _eigenlayerDepositFailsUnauthorized(DAIToken, depositAmount);
    }

    function test__dai__depositIntoStrategy(uint256 depositAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _testEigenlayerDepositIntoStrategy(DAIToken, depositAmount);
    }

    function test__dai___withdrawWithoutUndelegate(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _eigenlayerWithdrawWithoutUndelegate(DAIToken, depositAmount);
    }

    function test__dai__eigenlayerQueueAndCompleteMultipleWithdrawals(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 3);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _eigenlayerQueueAndCompleteMultipleWithdrawals(DAIToken, depositAmount);
    }

    function test__dai__delegateToOperatorRequiringSignature(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _delegateToOperatorRequiringSignature(DAIToken, depositAmount);
    }

    function test__dai__delegateToOperatorRequiringSignaturerRevertsWrongSignature(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _delegateToOperatorRequiringSignatureRevertsWrongSignature(
            DAIToken,
            depositAmount
        );
    }

    function test__dai__depositDelegateSlashAndWithdraw(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _depositDelegateSlashAndWithdraw(DAIToken, depositAmount);
    }

    function test__dai__depositDelegateSlashAndWithdrawRevertsInsufficientShares(
        uint256 depositAmount
    ) public {
        vm.assume(depositAmount > 2);
        vm.assume(depositAmount <= INITIAL_BALANCE);
        _depositDelegateSlashAndWithdrawRevertsInsufficientShares(
            DAIToken,
            depositAmount
        );
    }

    // =====================================================================
    // ============================== HELPERS ==============================
    // =====================================================================

    function _registerOperatorWithDelegationApprover(
        address operator
    ) internal {
        IDelegationManager.OperatorDetails
            memory operatorDetails = IDelegationManager.OperatorDetails({
                __deprecated_earningsReceiver: operator,
                delegationApprover: defaultApprover,
                stakerOptOutWindowBlocks: 0
            });
        _registerOperator(operator, operatorDetails, "");
    }

    // delegates to an operator that requires a delegationApprover signature
    // this helper function generates the required signature and calls delegateTo
    function _delegateToOperatorWhoRequiresSig(
        address staker,
        address operator,
        bytes32 salt
    ) internal {
        uint256 expiry = type(uint256).max;
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = _getApproverSignature(
                delegationSignerPrivateKey,
                staker,
                operator,
                salt,
                expiry
            );
        vm.startPrank(managerAgent);
        eigReserveManager.delegateTo(
            operator,
            approverSignatureAndExpiry.signature,
            approverSignatureAndExpiry.expiry,
            salt
        );
    }

    function _delegateToOperatorWhoRequiresSignatureRevertsWrongSignature(
        address staker,
        address operator,
        bytes32 salt
    ) internal {
        uint256 expiry = type(uint256).max;
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = _getApproverSignature(
                delegationSignerPrivateKey,
                staker,
                operator,
                salt,
                expiry
            );
        vm.startPrank(managerAgent);
        // wrong signature
        bytes
            memory wrongSignature = hex"1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c";
        vm.expectRevert();
        eigReserveManager.delegateTo(
            operator,
            wrongSignature,
            approverSignatureAndExpiry.expiry,
            salt
        );
    }

    function _registerOperator(
        address operator,
        IDelegationManager.OperatorDetails memory operatorDetails,
        string memory metadataURI
    ) internal {
        vm.startPrank(operator);
        IDelegationManager(HOLESKY_DELEGATION_MANAGER).registerAsOperator(
            operatorDetails,
            metadataURI
        );
    }

    function _registerOperatorWithApprover(
        address delegationApprover
    ) internal returns (address) {
        // Create operator address/keypair
        (address operator, ) = makeAddrAndKey("operator");

        // Create operator details
        IDelegationManager.OperatorDetails memory operatorDetails = IDelegationManager
            .OperatorDetails({
                delegationApprover: delegationApprover, // The delegation approver address
                stakerOptOutWindowBlocks: 50400, // ~7 days worth of blocks
                __deprecated_earningsReceiver: address(owner) // Set to owner address
            });

        // Register operator
        vm.startPrank(operator);
        IDelegationManager(HOLESKY_DELEGATION_MANAGER).registerAsOperator(
            operatorDetails,
            "metadata_uri"
        );
        vm.stopPrank();

        return operator;
    }

    /**
     * @notice internal function for calculating a signature from the delegationSigner corresponding to `_delegationSignerPrivateKey`, approving
     * the `staker` to delegate to `operator`, with the specified `salt`, and expiring at `expiry`.
     */
    function _getApproverSignature(
        uint256 _delegationSignerPrivateKey,
        address staker,
        address operator,
        bytes32 salt,
        uint256 expiry
    )
        internal
        view
        returns (
            ISignatureUtils.SignatureWithExpiry
                memory approverSignatureAndExpiry
        )
    {
        approverSignatureAndExpiry.expiry = expiry;
        {
            bytes32 digestHash = IDelegationManager(HOLESKY_DELEGATION_MANAGER)
                .calculateDelegationApprovalDigestHash(
                    staker,
                    operator,
                    IDelegationManager(HOLESKY_DELEGATION_MANAGER)
                        .delegationApprover(operator),
                    salt,
                    expiry
                );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                _delegationSignerPrivateKey,
                digestHash
            );
            approverSignatureAndExpiry.signature = abi.encodePacked(r, s, v);
        }
        return approverSignatureAndExpiry;
    }

    function _getOperatorShares(
        IStrategy strategy,
        address operator
    ) public returns (uint256) {
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = strategy;
        uint256[] memory shares = IDelegationManager(HOLESKY_DELEGATION_MANAGER)
            .getOperatorShares(operator, strategies);
        return shares[0];
    }

    function _createStrategy(IERC20 token) public returns (IStrategy) {
        IStrategy newStrategy = IStrategyFactory(HOLESKY_STRATEGY_FACTORY)
            .deployNewStrategy(token);
        return newStrategy;
    }

    function _createAndDepositIntoStrategy(
        IERC20 token,
        uint depositAmount
    ) public returns (IStrategy) {
        IStrategy newStrategy = IStrategyFactory(HOLESKY_STRATEGY_FACTORY)
            .deployNewStrategy(token);
        vm.startPrank(managerAgent);
        eigReserveManager.depositIntoStrategy(
            address(newStrategy),
            address(token),
            depositAmount
        );
        vm.stopPrank();
        return newStrategy;
    }

    // convert a single strategy, share, and token into arrays of length one
    function _getStrategySharesAndTokenArrays(
        IStrategy strategy,
        uint256 share,
        IERC20 token
    ) public returns (IStrategy[] memory, uint[] memory, IERC20[] memory) {
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = strategy;
        uint256[] memory shares = new uint256[](1);
        shares[0] = share;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(token);
        return (strategies, shares, tokens);
    }

    // note: this function assumes HOLESKY_EIGENLAYER_OPERATOR is the operator
    //       from which we want to withdraw shares
    function _completeWithdraw(
        uint nonce,
        uint32 startBlock,
        EigenlayerReserveManager eigReserveManager,
        IERC20[] memory tokens,
        uint256[] memory shares,
        IStrategy[] memory strategies
    ) public {
        vm.startPrank(managerAgent);
        eigReserveManager.completeQueuedWithdrawal(
            nonce,
            HOLESKY_EIGENLAYER_OPERATOR,
            startBlock,
            tokens,
            strategies,
            shares
        );
        vm.stopPrank();
    }

    function _testEigenlayerDepositIntoStrategy(
        IERC20 token,
        uint256 depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();
        vm.startPrank(managerAgent);

        // create a new strategy
        IStrategy newStrategy = _createStrategy(token);

        // Check initial states
        uint256 tokenBalanceBefore = token.balanceOf(
            address(eigReserveManager)
        );
        uint256 strategyBalanceBefore = token.balanceOf(address(newStrategy));
        uint256 sharesBefore = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );

        // deposit into new strategy
        eigReserveManager.depositIntoStrategy(
            address(newStrategy),
            address(token),
            depositAmount
        );

        // Check states after deposit
        uint256 tokenBalanceAfter = token.balanceOf(address(eigReserveManager));
        uint256 strategyBalanceAfter = token.balanceOf(address(newStrategy));

        // Verify token transfers happened correctly
        assertEq(
            tokenBalanceBefore - tokenBalanceAfter,
            depositAmount,
            "EigenlayerRM token balance not reduced correctly"
        );
        assertEq(
            strategyBalanceAfter - strategyBalanceBefore,
            depositAmount,
            "Strategy did not receive tokens"
        );
    }

    function _createEigenlayerStrategyDepositAndDelegate(
        IERC20 token,
        uint256 depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();

        // create a new strategy
        IStrategy newStrategy = _createAndDepositIntoStrategy(
            token,
            depositAmount
        );

        vm.startPrank(managerAgent);
        // Check shares before delegation
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = newStrategy;
        uint256 sharesBefore = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );
        assertEq(
            sharesBefore,
            0,
            "Operator should have 0 shares before delegation"
        );

        // Check strategy shares for the reserve manager
        uint256 strategyShares = IStrategy(newStrategy).shares(
            address(eigReserveManager)
        );
        assertEq(
            strategyShares,
            depositAmount,
            "Strategy shares not equal to deposit amount"
        );

        // delegate to registered operator
        eigReserveManager.delegateTo(HOLESKY_EIGENLAYER_OPERATOR, "", 0, 0x0);
        uint256 sharesAfter = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );

        // check that operator shares increased after delegate is called
        assertEq(
            sharesAfter,
            depositAmount,
            "Operator shares not equal to deposit amount after delegation"
        );

        // undelegate
        _undelegate();

        uint256 sharesAfterUndelegate = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );
        assertEq(sharesAfterUndelegate, 0);

        uint256[] memory shares = new uint256[](1);
        shares[0] = depositAmount;

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(token);

        // claim withdraw before minWithdrawalDelayBlocks has passed
        vm.expectRevert();
        _completeWithdraw(
            0,
            uint32(block.number),
            eigReserveManager,
            tokens,
            shares,
            strategies
        );
        uint32 withdrawStartBlock = uint32(block.number);

        // Get the current block number
        uint256 currentBlock = block.number;

        // Roll forward by 10 blocks so that minWithdrawalDelayBlocks passes
        vm.roll(currentBlock + 10);
        uint balBefore = token.balanceOf(address(eigReserveManager));
        _completeWithdraw(
            0,
            withdrawStartBlock,
            eigReserveManager,
            tokens,
            shares,
            strategies
        );
        uint balAfter = token.balanceOf(address(eigReserveManager));

        // check that eig LRM receives USDC back after completing withdrawal
        assertEq(balAfter - balBefore, depositAmount);
    }

    function _slashDelegator(IStrategy strategy, uint256 amount) public {
        // only the strategy manager can call delegationManager:decreaseDelegatedShares
        vm.startPrank(HOLESKY_STRATEGY_MANAGER);
        IDelegationManager(HOLESKY_DELEGATION_MANAGER).decreaseDelegatedShares(
            address(eigReserveManager),
            strategy,
            amount
        );
        vm.stopPrank();
    }

    function _slashStrategy(IStrategy strategy, uint256 amount) public {
        // only the delegation manager can call strategyManager:removeShares
        vm.startPrank(HOLESKY_DELEGATION_MANAGER);
        IStrategyManager(HOLESKY_STRATEGY_MANAGER).removeShares(
            address(eigReserveManager),
            strategy,
            amount
        );
        vm.stopPrank();
    }

    function _checkShares(IStrategy strategy, uint expectedShares) public {
        uint256 stakerSharesAfterSlash = IStrategyManager(
            HOLESKY_STRATEGY_MANAGER
        ).stakerStrategyShares(address(eigReserveManager), strategy);
        assertEq(
            stakerSharesAfterSlash,
            expectedShares,
            "Staker shares not properly slashed"
        );
        uint256 operatorSharesAfterSlash = IDelegationManager(
            HOLESKY_DELEGATION_MANAGER
        ).operatorShares(HOLESKY_EIGENLAYER_OPERATOR, strategy);
        assertEq(
            operatorSharesAfterSlash,
            expectedShares,
            "Operator shares not properly slashed"
        );
    }

    function _undelegate() public {
        vm.startPrank(managerAgent);
        eigReserveManager.undelegate();
        vm.stopPrank();
    }

    function _depositDelegateSlashAndWithdraw(
        IERC20 token,
        uint256 depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();

        // create a new strategy
        IStrategy newStrategy = _createAndDepositIntoStrategy(
            token,
            depositAmount
        );

        vm.startPrank(managerAgent);
        // Get initial shares from the strategy after deposit
        uint256 initialShares = IStrategyManager(HOLESKY_STRATEGY_MANAGER)
            .stakerStrategyShares(address(eigReserveManager), newStrategy);

        // delegate to registered operator
        eigReserveManager.delegateTo(HOLESKY_EIGENLAYER_OPERATOR, "", 0, 0x0);

        // do slashing
        uint slashAmount = depositAmount / 3;
        _slashDelegator(newStrategy, slashAmount);
        _slashStrategy(newStrategy, slashAmount);

        // Verify shares were decreased for both staker and operator
        uint stakerSharesAfterSlash = initialShares - slashAmount;
        _checkShares(newStrategy, stakerSharesAfterSlash);

        // undelegate
        _undelegate();
        uint32 withdrawStartBlock = uint32(block.number);

        (
            IStrategy[] memory strategies,
            uint256[] memory shares,
            IERC20[] memory tokens
        ) = _getStrategySharesAndTokenArrays(
                newStrategy,
                stakerSharesAfterSlash,
                token
            );

        vm.roll(block.number + 10);
        uint balBefore = token.balanceOf(address(eigReserveManager));
        _completeWithdraw(
            0,
            withdrawStartBlock,
            eigReserveManager,
            tokens,
            shares,
            strategies
        );
        uint balAfter = token.balanceOf(address(eigReserveManager));

        // check that eig LRM receives token back after completing withdrawal
        assertEq(balAfter - balBefore, stakerSharesAfterSlash);
    }

    // test that user indeed gets slashed and cannot withdraw the full amount of shares they deposited
    function _depositDelegateSlashAndWithdrawRevertsInsufficientShares(
        IERC20 token,
        uint256 depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();

        // create a new strategy
        IStrategy newStrategy = _createAndDepositIntoStrategy(
            token,
            depositAmount
        );
        vm.startPrank(managerAgent);
        // Get initial shares from the strategy after deposit
        uint256 initialShares = IStrategyManager(HOLESKY_STRATEGY_MANAGER)
            .stakerStrategyShares(address(eigReserveManager), newStrategy);

        // delegate to registered operator
        eigReserveManager.delegateTo(HOLESKY_EIGENLAYER_OPERATOR, "", 0, 0x0);

        // Calculate slash amount and remaining shares
        uint256 slashAmount = depositAmount / 3;
        uint256 expectedSharesAfterSlash = initialShares - slashAmount;

        (
            IStrategy[] memory strategies,
            uint256[] memory shares,
            IERC20[] memory tokens
        ) = _getStrategySharesAndTokenArrays(
                newStrategy,
                // Queue withdraw for slightly more shares than will be available after slashing
                expectedSharesAfterSlash + 1,
                token
            );

        _slashDelegator(newStrategy, slashAmount);
        _slashStrategy(newStrategy, slashAmount);
        _checkShares(newStrategy, expectedSharesAfterSlash);

        // Start withdrawal process
        _undelegate();
        uint32 withdrawStartBlock = uint32(block.number);

        // Move forward to pass withdrawal delay
        vm.roll(block.number + 10);

        // Try to complete withdrawal - should revert because we queued more shares than available after slashing
        vm.expectRevert();
        _completeWithdraw(
            0,
            withdrawStartBlock,
            eigReserveManager,
            tokens,
            shares,
            strategies
        );
    }

    function _eigenlayerDepositFailsUnauthorized(
        IERC20 token,
        uint256 depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();
        vm.startPrank(owner);
        // create a new strategy
        IStrategy newStrategy = _createStrategy(token);
        // deposit into new strategy
        vm.expectRevert();
        // only manager agent is allowed to deposit into strategy
        eigReserveManager.depositIntoStrategy(
            address(newStrategy),
            address(token),
            depositAmount
        );
    }

    function _callEigenlayerReserveManagerSetters() public {
        eigReserveManager.setOperatorName("operator2");
        eigReserveManager.setStrategyManager(HOLESKY_STRATEGY_MANAGER);
        eigReserveManager.setDelegationManager(HOLESKY_DELEGATION_MANAGER);
    }

    // deposit, then initiate withdraw directly without using undelegate
    function _eigenlayerWithdrawWithoutUndelegate(
        IERC20 token,
        uint depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();
        // create and deposit into strategy, then delegate to operator
        IStrategy newStrategy = _createAndDepositIntoStrategy(
            token,
            depositAmount
        );
        vm.startPrank(managerAgent);
        eigReserveManager.delegateTo(HOLESKY_EIGENLAYER_OPERATOR, "", 0, 0x0);

        // queue first withdrawal
        (
            IStrategy[] memory strategies,
            uint256[] memory shares,
            IERC20[] memory tokens
        ) = _getStrategySharesAndTokenArrays(
                newStrategy,
                depositAmount / 2,
                token
            );

        // Check that operator's shares decrease after queueWithdrawal
        uint256 operatorSharesBefore = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );
        eigReserveManager.queueWithdrawals(strategies, shares);
        uint256 operatorSharesAfter = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );
        assertEq(operatorSharesBefore - operatorSharesAfter, depositAmount / 2);

        // complete first withdraw
        vm.roll(block.number + 10);
        uint balBefore = token.balanceOf(address(eigReserveManager));
        _completeWithdraw(
            0,
            uint32(block.number - 10),
            eigReserveManager,
            tokens,
            shares,
            strategies
        );
        uint balAfter = token.balanceOf(address(eigReserveManager));
        assertEq(balAfter - balBefore, depositAmount / 2);

        // queue and complete withdraw a second time
        vm.roll(block.number + 30);
        vm.startPrank(managerAgent);
        eigReserveManager.queueWithdrawals(strategies, shares);
        uint32 secondWithdrawStartBlock = uint32(block.number);
        vm.roll(block.number + 50);

        vm.expectRevert(); // check that withdraw reverts due to incorrect nonce
        _completeWithdraw(
            2, // incorrect nonce (should be 1)
            secondWithdrawStartBlock,
            eigReserveManager,
            tokens,
            shares,
            strategies
        );

        _completeWithdraw(
            1, // increment nonce from 0 to 1
            secondWithdrawStartBlock,
            eigReserveManager,
            tokens,
            shares,
            strategies
        );
    }

    function _delegateToOperatorRequiringSignature(
        IERC20 token,
        uint256 depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();
        vm.startPrank(managerAgent);

        // create a new strategy
        IStrategy newStrategy = _createAndDepositIntoStrategy(
            token,
            depositAmount
        );

        // Check shares before delegation
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = newStrategy;
        uint256 sharesBefore = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_UNREGISTERED_OPERATOR
        );
        assertEq(
            sharesBefore,
            0,
            "Operator should have 0 shares before delegation"
        );

        // Check strategy shares for the reserve manager
        uint256 strategyShares = IStrategy(newStrategy).shares(
            address(eigReserveManager)
        );
        assertEq(
            strategyShares,
            depositAmount,
            "Strategy shares not equal to deposit amount"
        );

        _registerOperatorWithDelegationApprover(
            HOLESKY_EIGENLAYER_UNREGISTERED_OPERATOR
        );

        // delegate to operator
        _delegateToOperatorWhoRequiresSig(
            address(eigReserveManager),
            HOLESKY_EIGENLAYER_UNREGISTERED_OPERATOR,
            0
        );

        uint256 sharesAfter = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_UNREGISTERED_OPERATOR
        );

        // check that operator shares increased after delegate is called
        assertEq(
            sharesAfter,
            depositAmount,
            "Operator shares not equal to deposit amount after delegation"
        );
    }

    function _delegateToOperatorRequiringSignatureRevertsWrongSignature(
        IERC20 token,
        uint256 depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();
        vm.startPrank(managerAgent);

        // create a new strategy
        IStrategy newStrategy = _createAndDepositIntoStrategy(
            token,
            depositAmount
        );

        _registerOperatorWithDelegationApprover(
            HOLESKY_EIGENLAYER_UNREGISTERED_OPERATOR
        );

        _delegateToOperatorWhoRequiresSignatureRevertsWrongSignature(
            address(eigReserveManager),
            HOLESKY_EIGENLAYER_UNREGISTERED_OPERATOR,
            0
        );
    }

    function _eigenlayerQueueAndCompleteMultipleWithdrawals(
        IERC20 token,
        uint depositAmount
    ) public {
        _callEigenlayerReserveManagerSetters();

        // create and deposit into strategy, then delegate to operator
        IStrategy newStrategy = _createAndDepositIntoStrategy(
            token,
            depositAmount
        );
        vm.startPrank(managerAgent);
        eigReserveManager.delegateTo(HOLESKY_EIGENLAYER_OPERATOR, "", 0, 0x0);

        // queue multiple withdrawals with the same nonce
        IStrategy[] memory strategies = new IStrategy[](3);
        strategies[0] = newStrategy;
        strategies[1] = newStrategy;
        strategies[2] = newStrategy;
        uint256[] memory shares = new uint256[](3);
        shares[0] = depositAmount / 3;
        shares[1] = depositAmount / 3;
        shares[2] = depositAmount / 3;
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = IERC20(token);
        tokens[1] = IERC20(token);
        tokens[2] = IERC20(token);
        uint256 operatorSharesBefore = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );
        eigReserveManager.queueWithdrawals(strategies, shares);
        uint256 operatorSharesAfter = _getOperatorShares(
            newStrategy,
            HOLESKY_EIGENLAYER_OPERATOR
        );
        assertEq(
            operatorSharesBefore - operatorSharesAfter,
            (depositAmount / 3) * 3
        );
        uint blockNumberQueueWithdrawal = block.number;

        // complete all withdrawals at once
        vm.roll(block.number + 10);
        uint balBefore = token.balanceOf(address(eigReserveManager));
        _completeWithdraw(
            0, // nonce
            uint32(blockNumberQueueWithdrawal),
            eigReserveManager,
            tokens,
            shares,
            strategies
        );
        uint balAfter = token.balanceOf(address(eigReserveManager));
        assertEq(balAfter - balBefore, (depositAmount / 3) * 3);
    }
}
