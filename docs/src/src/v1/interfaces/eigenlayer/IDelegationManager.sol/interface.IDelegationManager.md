# IDelegationManager
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v1/interfaces/eigenlayer/IDelegationManager.sol)

**Inherits:**
[ISignatureUtils](/src/v1/interfaces/eigenlayer/ISignatureUtils.sol/interface.ISignatureUtils.md)

**Author:**
Layr Labs, Inc.

Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service

This is the contract for delegation in EigenLayer. The main functionalities of this contract are
- enabling anyone to register as an operator in EigenLayer
- allowing operators to specify parameters related to stakers who delegate to them
- enabling any staker to delegate its stake to the operator of its choice (a given staker can only delegate to a single operator at a time)
- enabling a staker to undelegate its assets from the operator it is delegated to (performed as part of the withdrawal process, initiated through the StrategyManager)


## Functions
### registerAsOperator

Registers the caller as an operator in EigenLayer.

*Once an operator is registered, they cannot 'deregister' as an operator, and they will forever be considered "delegated to themself".*

*This function will revert if the caller is already delegated to an operator.*

*Note that the `metadataURI` is *never stored * and is only emitted in the `OperatorMetadataURIUpdated` event*


```solidity
function registerAsOperator(OperatorDetails calldata registeringOperatorDetails, string calldata metadataURI)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`registeringOperatorDetails`|`OperatorDetails`|is the `OperatorDetails` for the operator.|
|`metadataURI`|`string`|is a URI for the operator's metadata, i.e. a link providing more details on the operator.|


### modifyOperatorDetails

Updates an operator's stored `OperatorDetails`.

*The caller must have previously registered as an operator in EigenLayer.*


```solidity
function modifyOperatorDetails(OperatorDetails calldata newOperatorDetails) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOperatorDetails`|`OperatorDetails`|is the updated `OperatorDetails` for the operator, to replace their current OperatorDetails`.|


### updateOperatorMetadataURI

Called by an operator to emit an `OperatorMetadataURIUpdated` event indicating the information has updated.

*Note that the `metadataURI` is *never stored * and is only emitted in the `OperatorMetadataURIUpdated` event*


```solidity
function updateOperatorMetadataURI(string calldata metadataURI) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|The URI for metadata associated with an operator|


### delegateTo

Caller delegates their stake to an operator.

*The approverSignatureAndExpiry is used in the event that:
1) the operator's `delegationApprover` address is set to a non-zero value.
AND
2) neither the operator nor their `delegationApprover` is the `msg.sender`, since in the event that the operator
or their delegationApprover is the `msg.sender`, then approval is assumed.*

*In the event that `approverSignatureAndExpiry` is not checked, its content is ignored entirely; it's recommended to use an empty input
in this case to save on complexity + gas costs*


```solidity
function delegateTo(address operator, SignatureWithExpiry memory approverSignatureAndExpiry, bytes32 approverSalt)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The account (`msg.sender`) is delegating its assets to for use in serving applications built on EigenLayer.|
|`approverSignatureAndExpiry`|`SignatureWithExpiry`|Verifies the operator approves of this delegation|
|`approverSalt`|`bytes32`|A unique single use value tied to an individual signature.|


### delegateToBySignature

Caller delegates a staker's stake to an operator with valid signatures from both parties.

*If `staker` is an EOA, then `stakerSignature` is verified to be a valid ECDSA stakerSignature from `staker`, indicating their intention for this action.*

*If `staker` is a contract, then `stakerSignature` will be checked according to EIP-1271.*

*the operator's `delegationApprover` address is set to a non-zero value.*

*neither the operator nor their `delegationApprover` is the `msg.sender`, since in the event that the operator or their delegationApprover
is the `msg.sender`, then approval is assumed.*

*This function will revert if the current `block.timestamp` is equal to or exceeds the expiry*

*In the case that `approverSignatureAndExpiry` is not checked, its content is ignored entirely; it's recommended to use an empty input
in this case to save on complexity + gas costs*


```solidity
function delegateToBySignature(
    address staker,
    address operator,
    SignatureWithExpiry memory stakerSignatureAndExpiry,
    SignatureWithExpiry memory approverSignatureAndExpiry,
    bytes32 approverSalt
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The account delegating stake to an `operator` account|
|`operator`|`address`|The account (`staker`) is delegating its assets to for use in serving applications built on EigenLayer.|
|`stakerSignatureAndExpiry`|`SignatureWithExpiry`|Signed data from the staker authorizing delegating stake to an operator|
|`approverSignatureAndExpiry`|`SignatureWithExpiry`|is a parameter that will be used for verifying that the operator approves of this delegation action in the event that:|
|`approverSalt`|`bytes32`|Is a salt used to help guarantee signature uniqueness. Each salt can only be used once by a given approver.|


### undelegate

Undelegates the staker from the operator who they are delegated to. Puts the staker into the "undelegation limbo" mode of the EigenPodManager
and queues a withdrawal of all of the staker's shares in the StrategyManager (to the staker), if necessary.

*Reverts if the `staker` is also an operator, since operators are not allowed to undelegate from themselves.*

*Reverts if the caller is not the staker, nor the operator who the staker is delegated to, nor the operator's specified "delegationApprover"*

*Reverts if the `staker` is already undelegated.*


```solidity
function undelegate(address staker) external returns (bytes32[] memory withdrawalRoot);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The account to be undelegated.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalRoot`|`bytes32[]`|The root of the newly queued withdrawal, if a withdrawal was queued. Otherwise just bytes32(0).|


### queueWithdrawals

Allows a staker to withdraw some shares. Withdrawn shares/strategies are immediately removed
from the staker. If the staker is delegated, withdrawn shares/strategies are also removed from
their operator.
All withdrawn shares/strategies are placed in a queue and can be fully withdrawn after a delay.


```solidity
function queueWithdrawals(QueuedWithdrawalParams[] calldata queuedWithdrawalParams)
    external
    returns (bytes32[] memory);
```

### completeQueuedWithdrawal

Used to complete the specified `withdrawal`. The caller must match `withdrawal.withdrawer`

*middlewareTimesIndex is unused, but will be used in the Slasher eventually*

*beaconChainETHStrategy shares are non-transferrable, so if `receiveAsTokens = false` and `withdrawal.withdrawer != withdrawal.staker`, note that
any beaconChainETHStrategy shares in the `withdrawal` will be _returned to the staker_, rather than transferred to the withdrawer, unlike shares in
any other strategies, which will be transferred to the withdrawer.*


```solidity
function completeQueuedWithdrawal(
    Withdrawal calldata withdrawal,
    IERC20[] calldata tokens,
    uint256 middlewareTimesIndex,
    bool receiveAsTokens
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawal`|`Withdrawal`|The Withdrawal to complete.|
|`tokens`|`IERC20[]`|Array in which the i-th entry specifies the `token` input to the 'withdraw' function of the i-th Strategy in the `withdrawal.strategies` array. This input can be provided with zero length if `receiveAsTokens` is set to 'false' (since in that case, this input will be unused)|
|`middlewareTimesIndex`|`uint256`|is the index in the operator that the staker who triggered the withdrawal was delegated to's middleware times array|
|`receiveAsTokens`|`bool`|If true, the shares specified in the withdrawal will be withdrawn from the specified strategies themselves and sent to the caller, through calls to `withdrawal.strategies[i].withdraw`. If false, then the shares in the specified strategies will simply be transferred to the caller directly.|


### completeQueuedWithdrawals

Array-ified version of `completeQueuedWithdrawal`.
Used to complete the specified `withdrawals`. The function caller must match `withdrawals[...].withdrawer`

*See `completeQueuedWithdrawal` for relevant dev tags*


```solidity
function completeQueuedWithdrawals(
    Withdrawal[] calldata withdrawals,
    IERC20[][] calldata tokens,
    uint256[] calldata middlewareTimesIndexes,
    bool[] calldata receiveAsTokens
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawals`|`Withdrawal[]`|The Withdrawals to complete.|
|`tokens`|`IERC20[][]`|Array of tokens for each Withdrawal. See `completeQueuedWithdrawal` for the usage of a single array.|
|`middlewareTimesIndexes`|`uint256[]`|One index to reference per Withdrawal. See `completeQueuedWithdrawal` for the usage of a single index.|
|`receiveAsTokens`|`bool[]`|Whether or not to complete each withdrawal as tokens. See `completeQueuedWithdrawal` for the usage of a single boolean.|


### increaseDelegatedShares

Increases a staker's delegated share balance in a strategy.

**If the staker is actively delegated*, then increases the `staker`'s delegated shares in `strategy` by `shares`. Otherwise does nothing.*

*Callable only by the StrategyManager or EigenPodManager.*


```solidity
function increaseDelegatedShares(address staker, IStrategy strategy, uint256 shares) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The address to increase the delegated shares for their operator.|
|`strategy`|`IStrategy`|The strategy in which to increase the delegated shares.|
|`shares`|`uint256`|The number of shares to increase.|


### decreaseDelegatedShares

Decreases a staker's delegated share balance in a strategy.

**If the staker is actively delegated*, then decreases the `staker`'s delegated shares in `strategy` by `shares`. Otherwise does nothing.*

*Callable only by the StrategyManager or EigenPodManager.*


```solidity
function decreaseDelegatedShares(address staker, IStrategy strategy, uint256 shares) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The address to increase the delegated shares for their operator.|
|`strategy`|`IStrategy`|The strategy in which to decrease the delegated shares.|
|`shares`|`uint256`|The number of shares to decrease.|


### setMinWithdrawalDelayBlocks

Owner-only function for modifying the value of the `minWithdrawalDelayBlocks` variable.


```solidity
function setMinWithdrawalDelayBlocks(uint256 newMinWithdrawalDelayBlocks) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMinWithdrawalDelayBlocks`|`uint256`|new value of `minWithdrawalDelayBlocks`.|


### setStrategyWithdrawalDelayBlocks

Called by owner to set the minimum withdrawal delay blocks for each passed in strategy
Note that the min number of blocks to complete a withdrawal of a strategy is
MAX(minWithdrawalDelayBlocks, strategyWithdrawalDelayBlocks[strategy])


```solidity
function setStrategyWithdrawalDelayBlocks(IStrategy[] calldata strategies, uint256[] calldata withdrawalDelayBlocks)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategies`|`IStrategy[]`|The strategies to set the minimum withdrawal delay blocks for|
|`withdrawalDelayBlocks`|`uint256[]`|The minimum withdrawal delay blocks to set for each strategy|


### delegatedTo

returns the address of the operator that `staker` is delegated to.

Mapping: staker => operator whom the staker is currently delegated to.

*Note that returning address(0) indicates that the staker is not actively delegated to any operator.*


```solidity
function delegatedTo(address staker) external view returns (address);
```

### operatorDetails

Returns the OperatorDetails struct associated with an `operator`.


```solidity
function operatorDetails(address operator) external view returns (OperatorDetails memory);
```

### delegationApprover

Returns the delegationApprover account for an operator


```solidity
function delegationApprover(address operator) external view returns (address);
```

### stakerOptOutWindowBlocks

Returns the stakerOptOutWindowBlocks for an operator


```solidity
function stakerOptOutWindowBlocks(address operator) external view returns (uint256);
```

### getOperatorShares

Given array of strategies, returns array of shares for the operator


```solidity
function getOperatorShares(address operator, IStrategy[] memory strategies) external view returns (uint256[] memory);
```

### getWithdrawalDelay

Given a list of strategies, return the minimum number of blocks that must pass to withdraw
from all the inputted strategies. Return value is >= minWithdrawalDelayBlocks as this is the global min withdrawal delay.


```solidity
function getWithdrawalDelay(IStrategy[] calldata strategies) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategies`|`IStrategy[]`|The strategies to check withdrawal delays for|


### operatorShares

returns the total number of shares in `strategy` that are delegated to `operator`.

Mapping: operator => strategy => total number of shares in the strategy delegated to the operator.

*By design, the following invariant should hold for each Strategy:
(operator's shares in delegation manager) = sum (shares above zero of all stakers delegated to operator)
= sum (delegateable shares of all stakers delegated to the operator)*


```solidity
function operatorShares(address operator, IStrategy strategy) external view returns (uint256);
```

### getDelegatableShares

Returns the number of actively-delegatable shares a staker has across all strategies.

*Returns two empty arrays in the case that the Staker has no actively-delegateable shares.*


```solidity
function getDelegatableShares(address staker) external view returns (IStrategy[] memory, uint256[] memory);
```

### isDelegated

Returns 'true' if `staker` *is* actively delegated, and 'false' otherwise.


```solidity
function isDelegated(address staker) external view returns (bool);
```

### isOperator

Returns true is an operator has previously registered for delegation.


```solidity
function isOperator(address operator) external view returns (bool);
```

### stakerNonce

Mapping: staker => number of signed delegation nonces (used in `delegateToBySignature`) from the staker that the contract has already checked


```solidity
function stakerNonce(address staker) external view returns (uint256);
```

### delegationApproverSaltIsSpent

Mapping: delegationApprover => 32-byte salt => whether or not the salt has already been used by the delegationApprover.

*Salts are used in the `delegateTo` and `delegateToBySignature` functions. Note that these functions only process the delegationApprover's
signature + the provided salt if the operator being delegated to has specified a nonzero address as their `delegationApprover`.*


```solidity
function delegationApproverSaltIsSpent(address _delegationApprover, bytes32 salt) external view returns (bool);
```

### minWithdrawalDelayBlocks

Minimum delay enforced by this contract for completing queued withdrawals. Measured in blocks, and adjustable by this contract's owner,
up to a maximum of `MAX_WITHDRAWAL_DELAY_BLOCKS`. Minimum value is 0 (i.e. no delay enforced).
Note that strategies each have a separate withdrawal delay, which can be greater than this value. So the minimum number of blocks that must pass
to withdraw a strategy is MAX(minWithdrawalDelayBlocks, strategyWithdrawalDelayBlocks[strategy])


```solidity
function minWithdrawalDelayBlocks() external view returns (uint256);
```

### strategyWithdrawalDelayBlocks

Minimum delay enforced by this contract per Strategy for completing queued withdrawals. Measured in blocks, and adjustable by this contract's owner,
up to a maximum of `MAX_WITHDRAWAL_DELAY_BLOCKS`. Minimum value is 0 (i.e. no delay enforced).


```solidity
function strategyWithdrawalDelayBlocks(IStrategy strategy) external view returns (uint256);
```

### beaconChainETHStrategy

return address of the beaconChainETHStrategy


```solidity
function beaconChainETHStrategy() external view returns (IStrategy);
```

### calculateCurrentStakerDelegationDigestHash

Calculates the digestHash for a `staker` to sign to delegate to an `operator`


```solidity
function calculateCurrentStakerDelegationDigestHash(address staker, address operator, uint256 expiry)
    external
    view
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The signing staker|
|`operator`|`address`|The operator who is being delegated to|
|`expiry`|`uint256`|The desired expiry time of the staker's signature|


### calculateStakerDelegationDigestHash

Calculates the digest hash to be signed and used in the `delegateToBySignature` function


```solidity
function calculateStakerDelegationDigestHash(address staker, uint256 _stakerNonce, address operator, uint256 expiry)
    external
    view
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The signing staker|
|`_stakerNonce`|`uint256`|The nonce of the staker. In practice we use the staker's current nonce, stored at `stakerNonce[staker]`|
|`operator`|`address`|The operator who is being delegated to|
|`expiry`|`uint256`|The desired expiry time of the staker's signature|


### calculateDelegationApprovalDigestHash

Calculates the digest hash to be signed by the operator's delegationApprove and used in the `delegateTo` and `delegateToBySignature` functions.


```solidity
function calculateDelegationApprovalDigestHash(
    address staker,
    address operator,
    address _delegationApprover,
    bytes32 approverSalt,
    uint256 expiry
) external view returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The account delegating their stake|
|`operator`|`address`|The account receiving delegated stake|
|`_delegationApprover`|`address`|the operator's `delegationApprover` who will be signing the delegationHash (in general)|
|`approverSalt`|`bytes32`|A unique and single use value associated with the approver signature.|
|`expiry`|`uint256`|Time after which the approver's signature becomes invalid|


### DOMAIN_TYPEHASH

The EIP-712 typehash for the contract's domain


```solidity
function DOMAIN_TYPEHASH() external view returns (bytes32);
```

### STAKER_DELEGATION_TYPEHASH

The EIP-712 typehash for the StakerDelegation struct used by the contract


```solidity
function STAKER_DELEGATION_TYPEHASH() external view returns (bytes32);
```

### DELEGATION_APPROVAL_TYPEHASH

The EIP-712 typehash for the DelegationApproval struct used by the contract


```solidity
function DELEGATION_APPROVAL_TYPEHASH() external view returns (bytes32);
```

### domainSeparator

Getter function for the current EIP-712 domain separator for this contract.

*The domain separator will change in the event of a fork that changes the ChainID.*

*By introducing a domain separator the DApp developers are guaranteed that there can be no signature collision.
for more detailed information please read EIP-712.*


```solidity
function domainSeparator() external view returns (bytes32);
```

### cumulativeWithdrawalsQueued

Mapping: staker => cumulative number of queued withdrawals they have ever initiated.

*This only increments (doesn't decrement), and is used to help ensure that otherwise identical withdrawals have unique hashes.*


```solidity
function cumulativeWithdrawalsQueued(address staker) external view returns (uint256);
```

### calculateWithdrawalRoot

Returns the keccak256 hash of `withdrawal`.


```solidity
function calculateWithdrawalRoot(Withdrawal memory withdrawal) external pure returns (bytes32);
```

## Events
### OperatorRegistered

```solidity
event OperatorRegistered(address indexed operator, OperatorDetails operatorDetails);
```

### OperatorDetailsModified
Emitted when an operator updates their OperatorDetails to @param newOperatorDetails


```solidity
event OperatorDetailsModified(address indexed operator, OperatorDetails newOperatorDetails);
```

### OperatorMetadataURIUpdated
Emitted when @param operator indicates that they are updating their MetadataURI string

*Note that these strings are *never stored in storage* and are instead purely emitted in events for off-chain indexing*


```solidity
event OperatorMetadataURIUpdated(address indexed operator, string metadataURI);
```

### OperatorSharesIncreased
Emitted whenever an operator's shares are increased for a given strategy. Note that shares is the delta in the operator's shares.


```solidity
event OperatorSharesIncreased(address indexed operator, address staker, IStrategy strategy, uint256 shares);
```

### OperatorSharesDecreased
Emitted whenever an operator's shares are decreased for a given strategy. Note that shares is the delta in the operator's shares.


```solidity
event OperatorSharesDecreased(address indexed operator, address staker, IStrategy strategy, uint256 shares);
```

### StakerDelegated
Emitted when @param staker delegates to @param operator.


```solidity
event StakerDelegated(address indexed staker, address indexed operator);
```

### StakerUndelegated
Emitted when @param staker undelegates from @param operator.


```solidity
event StakerUndelegated(address indexed staker, address indexed operator);
```

### StakerForceUndelegated
Emitted when @param staker is undelegated via a call not originating from the staker themself


```solidity
event StakerForceUndelegated(address indexed staker, address indexed operator);
```

### WithdrawalQueued
Emitted when a new withdrawal is queued.


```solidity
event WithdrawalQueued(bytes32 withdrawalRoot, Withdrawal withdrawal);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalRoot`|`bytes32`|Is the hash of the `withdrawal`.|
|`withdrawal`|`Withdrawal`|Is the withdrawal itself.|

### WithdrawalCompleted
Emitted when a queued withdrawal is completed


```solidity
event WithdrawalCompleted(bytes32 withdrawalRoot);
```

### MinWithdrawalDelayBlocksSet
Emitted when the `minWithdrawalDelayBlocks` variable is modified from `previousValue` to `newValue`.


```solidity
event MinWithdrawalDelayBlocksSet(uint256 previousValue, uint256 newValue);
```

### StrategyWithdrawalDelayBlocksSet
Emitted when the `strategyWithdrawalDelayBlocks` variable is modified from `previousValue` to `newValue`.


```solidity
event StrategyWithdrawalDelayBlocksSet(IStrategy strategy, uint256 previousValue, uint256 newValue);
```

## Structs
### OperatorDetails

```solidity
struct OperatorDetails {
    address __deprecated_earningsReceiver;
    address delegationApprover;
    uint32 stakerOptOutWindowBlocks;
}
```

### StakerDelegation
Abstract struct used in calculating an EIP712 signature for a staker to approve that they (the staker themselves) delegate to a specific operator.

*Used in computing the `STAKER_DELEGATION_TYPEHASH` and as a reference in the computation of the stakerDigestHash in the `delegateToBySignature` function.*


```solidity
struct StakerDelegation {
    address staker;
    address operator;
    uint256 nonce;
    uint256 expiry;
}
```

### DelegationApproval
Abstract struct used in calculating an EIP712 signature for an operator's delegationApprover to approve that a specific staker delegate to the operator.

*Used in computing the `DELEGATION_APPROVAL_TYPEHASH` and as a reference in the computation of the approverDigestHash in the `_delegate` function.*


```solidity
struct DelegationApproval {
    address staker;
    address operator;
    bytes32 salt;
    uint256 expiry;
}
```

### Withdrawal
Struct type used to specify an existing queued withdrawal. Rather than storing the entire struct, only a hash is stored.
In functions that operate on existing queued withdrawals -- e.g. completeQueuedWithdrawal`, the data is resubmitted and the hash of the submitted
data is computed by `calculateWithdrawalRoot` and checked against the stored hash in order to confirm the integrity of the submitted data.


```solidity
struct Withdrawal {
    address staker;
    address delegatedTo;
    address withdrawer;
    uint256 nonce;
    uint32 startBlock;
    IStrategy[] strategies;
    uint256[] shares;
}
```

### QueuedWithdrawalParams

```solidity
struct QueuedWithdrawalParams {
    IStrategy[] strategies;
    uint256[] shares;
    address withdrawer;
}
```

