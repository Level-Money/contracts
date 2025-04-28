# IRewardsCoordinator
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/interfaces/eigenlayer/IRewardsCoordinator.sol)

**Author:**
Layr Labs, Inc.

Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service

Allows AVSs to make "Rewards Submissions", which get distributed amongst the AVSs' confirmed
Operators and the Stakers delegated to those Operators.
Calculations are performed based on the completed RewardsSubmission, with the results posted in
a Merkle root against which Stakers & Operators can make claims.


## Functions
### rewardsUpdater

VIEW FUNCTIONS

The address of the entity that can update the contract with new merkle roots


```solidity
function rewardsUpdater() external view returns (address);
```

### CALCULATION_INTERVAL_SECONDS

The interval in seconds at which the calculation for a RewardsSubmission distribution is done.

*Rewards Submission durations must be multiples of this interval.*


```solidity
function CALCULATION_INTERVAL_SECONDS() external view returns (uint32);
```

### MAX_REWARDS_DURATION

The maximum amount of time (seconds) that a RewardsSubmission can span over


```solidity
function MAX_REWARDS_DURATION() external view returns (uint32);
```

### MAX_RETROACTIVE_LENGTH

max amount of time (seconds) that a submission can start in the past


```solidity
function MAX_RETROACTIVE_LENGTH() external view returns (uint32);
```

### MAX_FUTURE_LENGTH

max amount of time (seconds) that a submission can start in the future


```solidity
function MAX_FUTURE_LENGTH() external view returns (uint32);
```

### GENESIS_REWARDS_TIMESTAMP

absolute min timestamp (seconds) that a submission can start at


```solidity
function GENESIS_REWARDS_TIMESTAMP() external view returns (uint32);
```

### activationDelay

Delay in timestamp (seconds) before a posted root can be claimed against


```solidity
function activationDelay() external view returns (uint32);
```

### claimerFor

Mapping: earner => the address of the entity who can call `processClaim` on behalf of the earner


```solidity
function claimerFor(address earner) external view returns (address);
```

### cumulativeClaimed

Mapping: claimer => token => total amount claimed


```solidity
function cumulativeClaimed(address claimer, IERC20 token) external view returns (uint256);
```

### globalOperatorCommissionBips

the commission for all operators across all avss


```solidity
function globalOperatorCommissionBips() external view returns (uint16);
```

### operatorCommissionBips

the commission for a specific operator for a specific avs
NOTE: Currently unused and simply returns the globalOperatorCommissionBips value but will be used in future release


```solidity
function operatorCommissionBips(address operator, address avs) external view returns (uint16);
```

### calculateEarnerLeafHash

return the hash of the earner's leaf


```solidity
function calculateEarnerLeafHash(EarnerTreeMerkleLeaf calldata leaf) external pure returns (bytes32);
```

### calculateTokenLeafHash

returns the hash of the earner's token leaf


```solidity
function calculateTokenLeafHash(TokenTreeMerkleLeaf calldata leaf) external pure returns (bytes32);
```

### checkClaim

returns 'true' if the claim would currently pass the check in `processClaims`
but will revert if not valid


```solidity
function checkClaim(RewardsMerkleClaim calldata claim) external view returns (bool);
```

### currRewardsCalculationEndTimestamp

The timestamp until which RewardsSubmissions have been calculated


```solidity
function currRewardsCalculationEndTimestamp() external view returns (uint32);
```

### getDistributionRootsLength

returns the number of distribution roots posted


```solidity
function getDistributionRootsLength() external view returns (uint256);
```

### getDistributionRootAtIndex

returns the distributionRoot at the specified index


```solidity
function getDistributionRootAtIndex(uint256 index) external view returns (DistributionRoot memory);
```

### getCurrentDistributionRoot

returns the current distributionRoot


```solidity
function getCurrentDistributionRoot() external view returns (DistributionRoot memory);
```

### getCurrentClaimableDistributionRoot

loop through the distribution roots from reverse and get latest root that is not disabled and activated
i.e. a root that can be claimed against


```solidity
function getCurrentClaimableDistributionRoot() external view returns (DistributionRoot memory);
```

### getRootIndexFromHash

loop through distribution roots from reverse and return index from hash


```solidity
function getRootIndexFromHash(bytes32 rootHash) external view returns (uint32);
```

### createAVSRewardsSubmission

EXTERNAL FUNCTIONS

Creates a new rewards submission on behalf of an AVS, to be split amongst the
set of stakers delegated to operators who are registered to the `avs`

*Expected to be called by the ServiceManager of the AVS on behalf of which the submission is being made*

*The duration of the `rewardsSubmission` cannot exceed `MAX_REWARDS_DURATION`*

*The tokens are sent to the `RewardsCoordinator` contract*

*Strategies must be in ascending order of addresses to check for duplicates*

*This function will revert if the `rewardsSubmission` is malformed,
e.g. if the `strategies` and `weights` arrays are of non-equal lengths*


```solidity
function createAVSRewardsSubmission(RewardsSubmission[] calldata rewardsSubmissions) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rewardsSubmissions`|`RewardsSubmission[]`|The rewards submissions being created|


### createRewardsForAllSubmission

similar to `createAVSRewardsSubmission` except the rewards are split amongst *all* stakers
rather than just those delegated to operators who are registered to a single avs and is
a permissioned call based on isRewardsForAllSubmitter mapping.


```solidity
function createRewardsForAllSubmission(RewardsSubmission[] calldata rewardsSubmission) external;
```

### createRewardsForAllEarners

Creates a new rewards submission for all earners across all AVSs.
Earners in this case indicating all operators and their delegated stakers. Undelegated stake
is not rewarded from this RewardsSubmission. This interface is only callable
by the token hopper contract from the Eigen Foundation


```solidity
function createRewardsForAllEarners(RewardsSubmission[] calldata rewardsSubmissions) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rewardsSubmissions`|`RewardsSubmission[]`|The rewards submissions being created|


### processClaim

Claim rewards against a given root (read from _distributionRoots[claim.rootIndex]).
Earnings are cumulative so earners don't have to claim against all distribution roots they have earnings for,
they can simply claim against the latest root and the contract will calculate the difference between
their cumulativeEarnings and cumulativeClaimed. This difference is then transferred to recipient address.

*only callable by the valid claimer, that is
if claimerFor[claim.earner] is address(0) then only the earner can claim, otherwise only
claimerFor[claim.earner] can claim the rewards.*


```solidity
function processClaim(RewardsMerkleClaim calldata claim, address recipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claim`|`RewardsMerkleClaim`|The RewardsMerkleClaim to be processed. Contains the root index, earner, token leaves, and required proofs|
|`recipient`|`address`|The address recipient that receives the ERC20 rewards|


### submitRoot

Creates a new distribution root. activatedAt is set to block.timestamp + activationDelay

*Only callable by the rewardsUpdater*


```solidity
function submitRoot(bytes32 root, uint32 rewardsCalculationEndTimestamp) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`root`|`bytes32`|The merkle root of the distribution|
|`rewardsCalculationEndTimestamp`|`uint32`|The timestamp (seconds) until which rewards have been calculated|


### disableRoot

allow the rewardsUpdater to disable/cancel a pending root submission in case of an error


```solidity
function disableRoot(uint32 rootIndex) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rootIndex`|`uint32`|The index of the root to be disabled|


### setClaimerFor

Sets the address of the entity that can call `processClaim` on behalf of the earner (msg.sender)

*Only callable by the `earner`*


```solidity
function setClaimerFor(address claimer) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimer`|`address`|The address of the entity that can claim rewards on behalf of the earner|


### setActivationDelay

Sets the delay in timestamp before a posted root can be claimed against

*Only callable by the contract owner*


```solidity
function setActivationDelay(uint32 _activationDelay) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_activationDelay`|`uint32`|Delay in timestamp (seconds) before a posted root can be claimed against|


### setGlobalOperatorCommission

Sets the global commission for all operators across all avss

*Only callable by the contract owner*


```solidity
function setGlobalOperatorCommission(uint16 _globalCommissionBips) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_globalCommissionBips`|`uint16`|The commission for all operators across all avss|


### setRewardsUpdater

Sets the permissioned `rewardsUpdater` address which can post new roots

*Only callable by the contract owner*


```solidity
function setRewardsUpdater(address _rewardsUpdater) external;
```

### setRewardsForAllSubmitter

Sets the permissioned `rewardsForAllSubmitter` address which can submit createRewardsForAllSubmission

*Only callable by the contract owner*


```solidity
function setRewardsForAllSubmitter(address _submitter, bool _newValue) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_submitter`|`address`|The address of the rewardsForAllSubmitter|
|`_newValue`|`bool`|The new value for isRewardsForAllSubmitter|


## Events
### AVSRewardsSubmissionCreated
EVENTS ///

emitted when an AVS creates a valid RewardsSubmission


```solidity
event AVSRewardsSubmissionCreated(
    address indexed avs,
    uint256 indexed submissionNonce,
    bytes32 indexed rewardsSubmissionHash,
    RewardsSubmission rewardsSubmission
);
```

### RewardsSubmissionForAllCreated
emitted when a valid RewardsSubmission is created for all stakers by a valid submitter


```solidity
event RewardsSubmissionForAllCreated(
    address indexed submitter,
    uint256 indexed submissionNonce,
    bytes32 indexed rewardsSubmissionHash,
    RewardsSubmission rewardsSubmission
);
```

### RewardsSubmissionForAllEarnersCreated
emitted when a valid RewardsSubmission is created when rewardAllStakersAndOperators is called


```solidity
event RewardsSubmissionForAllEarnersCreated(
    address indexed tokenHopper,
    uint256 indexed submissionNonce,
    bytes32 indexed rewardsSubmissionHash,
    RewardsSubmission rewardsSubmission
);
```

### RewardsUpdaterSet
rewardsUpdater is responsible for submiting DistributionRoots, only owner can set rewardsUpdater


```solidity
event RewardsUpdaterSet(address indexed oldRewardsUpdater, address indexed newRewardsUpdater);
```

### RewardsForAllSubmitterSet

```solidity
event RewardsForAllSubmitterSet(address indexed rewardsForAllSubmitter, bool indexed oldValue, bool indexed newValue);
```

### ActivationDelaySet

```solidity
event ActivationDelaySet(uint32 oldActivationDelay, uint32 newActivationDelay);
```

### GlobalCommissionBipsSet

```solidity
event GlobalCommissionBipsSet(uint16 oldGlobalCommissionBips, uint16 newGlobalCommissionBips);
```

### ClaimerForSet

```solidity
event ClaimerForSet(address indexed earner, address indexed oldClaimer, address indexed claimer);
```

### DistributionRootSubmitted
rootIndex is the specific array index of the newly created root in the storage array


```solidity
event DistributionRootSubmitted(
    uint32 indexed rootIndex, bytes32 indexed root, uint32 indexed rewardsCalculationEndTimestamp, uint32 activatedAt
);
```

### DistributionRootDisabled

```solidity
event DistributionRootDisabled(uint32 indexed rootIndex);
```

### RewardsClaimed
root is one of the submitted distribution roots that was claimed against


```solidity
event RewardsClaimed(
    bytes32 root,
    address indexed earner,
    address indexed claimer,
    address indexed recipient,
    IERC20 token,
    uint256 claimedAmount
);
```

## Structs
### StrategyAndMultiplier
STRUCTS ///

A linear combination of strategies and multipliers for AVSs to weigh
EigenLayer strategies.


```solidity
struct StrategyAndMultiplier {
    IStrategy strategy;
    uint96 multiplier;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IStrategy`|The EigenLayer strategy to be used for the rewards submission|
|`multiplier`|`uint96`|The weight of the strategy in the rewards submission|

### RewardsSubmission
Sliding Window for valid RewardsSubmission startTimestamp
Scenario A: GENESIS_REWARDS_TIMESTAMP IS WITHIN RANGE
<-----MAX_RETROACTIVE_LENGTH-----> t (block.timestamp) <---MAX_FUTURE_LENGTH--->
<--------------------valid range for startTimestamp------------------------>
^
GENESIS_REWARDS_TIMESTAMP
Scenario B: GENESIS_REWARDS_TIMESTAMP IS OUT OF RANGE
<-----MAX_RETROACTIVE_LENGTH-----> t (block.timestamp) <---MAX_FUTURE_LENGTH--->
<------------------------valid range for startTimestamp------------------------>
^
GENESIS_REWARDS_TIMESTAMP

RewardsSubmission struct submitted by AVSs when making rewards for their operators and stakers
RewardsSubmission can be for a time range within the valid window for startTimestamp and must be within max duration.
See `createAVSRewardsSubmission()` for more details.


```solidity
struct RewardsSubmission {
    StrategyAndMultiplier[] strategiesAndMultipliers;
    IERC20 token;
    uint256 amount;
    uint32 startTimestamp;
    uint32 duration;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`strategiesAndMultipliers`|`StrategyAndMultiplier[]`|The strategies and their relative weights cannot have duplicate strategies and need to be sorted in ascending address order|
|`token`|`IERC20`|The rewards token to be distributed|
|`amount`|`uint256`|The total amount of tokens to be distributed|
|`startTimestamp`|`uint32`|The timestamp (seconds) at which the submission range is considered for distribution could start in the past or in the future but within a valid range. See the diagram above.|
|`duration`|`uint32`|The duration of the submission range in seconds. Must be <= MAX_REWARDS_DURATION|

### DistributionRoot
A distribution root is a merkle root of the distribution of earnings for a given period.
The RewardsCoordinator stores all historical distribution roots so that earners can claim their earnings against older roots
if they wish but the merkle tree contains the cumulative earnings of all earners and tokens for a given period so earners (or their claimers if set)
only need to claim against the latest root to claim all available earnings.


```solidity
struct DistributionRoot {
    bytes32 root;
    uint32 rewardsCalculationEndTimestamp;
    uint32 activatedAt;
    bool disabled;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`root`|`bytes32`|The merkle root of the distribution|
|`rewardsCalculationEndTimestamp`|`uint32`|The timestamp (seconds) until which rewards have been calculated|
|`activatedAt`|`uint32`|The timestamp (seconds) at which the root can be claimed against|
|`disabled`|`bool`||

### EarnerTreeMerkleLeaf
Internal leaf in the merkle tree for the earner's account leaf


```solidity
struct EarnerTreeMerkleLeaf {
    address earner;
    bytes32 earnerTokenRoot;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`earner`|`address`|The address of the earner|
|`earnerTokenRoot`|`bytes32`|The merkle root of the earner's token subtree Each leaf in the earner's token subtree is a TokenTreeMerkleLeaf|

### TokenTreeMerkleLeaf
The actual leaves in the distribution merkle tree specifying the token earnings
for the respective earner's subtree. Each leaf is a claimable amount of a token for an earner.


```solidity
struct TokenTreeMerkleLeaf {
    IERC20 token;
    uint256 cumulativeEarnings;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`token`|`IERC20`|The token for which the earnings are being claimed|
|`cumulativeEarnings`|`uint256`|The cumulative earnings of the earner for the token|

### RewardsMerkleClaim
A claim against a distribution root called by an
earners claimer (could be the earner themselves). Each token claim will claim the difference
between the cumulativeEarnings of the earner and the cumulativeClaimed of the claimer.
Each claim can specify which of the earner's earned tokens they want to claim.
See `processClaim()` for more details.

*The merkle tree is structured with the merkle root at the top and EarnerTreeMerkleLeaf as internal leaves
in the tree. Each earner leaf has its own subtree with TokenTreeMerkleLeaf as leaves in the subtree.
To prove a claim against a specified rootIndex(which specifies the distributionRoot being used),
the claim will first verify inclusion of the earner leaf in the tree against _distributionRoots[rootIndex].root.
Then for each token, it will verify inclusion of the token leaf in the earner's subtree against the earner's earnerTokenRoot.*


```solidity
struct RewardsMerkleClaim {
    uint32 rootIndex;
    uint32 earnerIndex;
    bytes earnerTreeProof;
    EarnerTreeMerkleLeaf earnerLeaf;
    uint32[] tokenIndices;
    bytes[] tokenTreeProofs;
    TokenTreeMerkleLeaf[] tokenLeaves;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`rootIndex`|`uint32`|The index of the root in the list of DistributionRoots|
|`earnerIndex`|`uint32`|The index of the earner's account root in the merkle tree|
|`earnerTreeProof`|`bytes`|The proof of the earner's EarnerTreeMerkleLeaf against the merkle root|
|`earnerLeaf`|`EarnerTreeMerkleLeaf`|The earner's EarnerTreeMerkleLeaf struct, providing the earner address and earnerTokenRoot|
|`tokenIndices`|`uint32[]`|The indices of the token leaves in the earner's subtree|
|`tokenTreeProofs`|`bytes[]`|The proofs of the token leaves against the earner's earnerTokenRoot|
|`tokenLeaves`|`TokenTreeMerkleLeaf[]`|The token leaves to be claimed|

