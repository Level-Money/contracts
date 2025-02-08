# IStrategyManager
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/interfaces/eigenlayer/IStrategyManager.sol)

**Author:**
Layr Labs, Inc.

Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service

See the `StrategyManager` contract itself for implementation details.


## Functions
### depositIntoStrategy

Deposits `amount` of `token` into the specified `strategy`, with the resultant shares credited to `msg.sender`

*The `msg.sender` must have previously approved this contract to transfer at least `amount` of `token` on their behalf.*

*Cannot be called by an address that is 'frozen' (this function will revert if the `msg.sender` is frozen).
WARNING: Depositing tokens that allow reentrancy (eg. ERC-777) into a strategy is not recommended.  This can lead to attack vectors
where the token balance and corresponding strategy shares are not in sync upon reentrancy.*


```solidity
function depositIntoStrategy(IStrategy strategy, IERC20 token, uint256 amount) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IStrategy`|is the specified strategy where deposit is to be made,|
|`token`|`IERC20`|is the denomination in which the deposit is to be made,|
|`amount`|`uint256`|is the amount of token to be deposited in the strategy by the staker|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of new shares in the `strategy` created as part of the action.|


### depositIntoStrategyWithSignature

Used for depositing an asset into the specified strategy with the resultant shares credited to `staker`,
who must sign off on the action.
Note that the assets are transferred out/from the `msg.sender`, not from the `staker`; this function is explicitly designed
purely to help one address deposit 'for' another.

*The `msg.sender` must have previously approved this contract to transfer at least `amount` of `token` on their behalf.*

*A signature is required for this function to eliminate the possibility of griefing attacks, specifically those
targeting stakers who may be attempting to undelegate.*

*Cannot be called if thirdPartyTransfersForbidden is set to true for this strategy
WARNING: Depositing tokens that allow reentrancy (eg. ERC-777) into a strategy is not recommended.  This can lead to attack vectors
where the token balance and corresponding strategy shares are not in sync upon reentrancy*


```solidity
function depositIntoStrategyWithSignature(
    IStrategy strategy,
    IERC20 token,
    uint256 amount,
    address staker,
    uint256 expiry,
    bytes memory signature
) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IStrategy`|is the specified strategy where deposit is to be made,|
|`token`|`IERC20`|is the denomination in which the deposit is to be made,|
|`amount`|`uint256`|is the amount of token to be deposited in the strategy by the staker|
|`staker`|`address`|the staker that the deposited assets will be credited to|
|`expiry`|`uint256`|the timestamp at which the signature expires|
|`signature`|`bytes`|is a valid signature from the `staker`. either an ECDSA signature if the `staker` is an EOA, or data to forward following EIP-1271 if the `staker` is a contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of new shares in the `strategy` created as part of the action.|


### removeShares

Used by the DelegationManager to remove a Staker's shares from a particular strategy when entering the withdrawal queue


```solidity
function removeShares(address staker, IStrategy strategy, uint256 shares) external;
```

### addShares

Used by the DelegationManager to award a Staker some shares that have passed through the withdrawal queue


```solidity
function addShares(address staker, IERC20 token, IStrategy strategy, uint256 shares) external;
```

### withdrawSharesAsTokens

Used by the DelegationManager to convert withdrawn shares to tokens and send them to a recipient


```solidity
function withdrawSharesAsTokens(address recipient, IStrategy strategy, uint256 shares, IERC20 token) external;
```

### stakerStrategyShares

Returns the current shares of `user` in `strategy`


```solidity
function stakerStrategyShares(address user, IStrategy strategy) external view returns (uint256 shares);
```

### getDeposits

Get all details on the staker's deposits and corresponding shares


```solidity
function getDeposits(address staker) external view returns (IStrategy[] memory, uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|The staker of interest, whose deposits this function will fetch|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IStrategy[]`|(staker's strategies, shares in these strategies)|
|`<none>`|`uint256[]`||


### stakerStrategyListLength

Simple getter function that returns `stakerStrategyList[staker].length`.


```solidity
function stakerStrategyListLength(address staker) external view returns (uint256);
```

### addStrategiesToDepositWhitelist

Owner-only function that adds the provided Strategies to the 'whitelist' of strategies that stakers can deposit into


```solidity
function addStrategiesToDepositWhitelist(
    IStrategy[] calldata strategiesToWhitelist,
    bool[] calldata thirdPartyTransfersForbiddenValues
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategiesToWhitelist`|`IStrategy[]`|Strategies that will be added to the `strategyIsWhitelistedForDeposit` mapping (if they aren't in it already)|
|`thirdPartyTransfersForbiddenValues`|`bool[]`|bool values to set `thirdPartyTransfersForbidden` to for each strategy|


### removeStrategiesFromDepositWhitelist

Owner-only function that removes the provided Strategies from the 'whitelist' of strategies that stakers can deposit into


```solidity
function removeStrategiesFromDepositWhitelist(IStrategy[] calldata strategiesToRemoveFromWhitelist) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategiesToRemoveFromWhitelist`|`IStrategy[]`|Strategies that will be removed to the `strategyIsWhitelistedForDeposit` mapping (if they are in it)|


### setThirdPartyTransfersForbidden

If true for a strategy, a user cannot depositIntoStrategyWithSignature into that strategy for another staker
and also when performing DelegationManager.queueWithdrawals, a staker can only withdraw to themselves.
Defaulted to false for all existing strategies.


```solidity
function setThirdPartyTransfersForbidden(IStrategy strategy, bool value) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`IStrategy`|The strategy to set `thirdPartyTransfersForbidden` value to|
|`value`|`bool`|bool value to set `thirdPartyTransfersForbidden` to|


### delegation

Returns the single, central Delegation contract of EigenLayer


```solidity
function delegation() external view returns (IDelegationManager);
```

### slasher

Returns the single, central Slasher contract of EigenLayer


```solidity
function slasher() external view returns (ISlasher);
```

### strategyWhitelister

Returns the EigenPodManager contract of EigenLayer

Returns the address of the `strategyWhitelister`


```solidity
function strategyWhitelister() external view returns (address);
```

### strategyIsWhitelistedForDeposit

Returns bool for whether or not `strategy` is whitelisted for deposit


```solidity
function strategyIsWhitelistedForDeposit(IStrategy strategy) external view returns (bool);
```

### setStrategyWhitelister

Owner-only function to change the `strategyWhitelister` address.


```solidity
function setStrategyWhitelister(address newStrategyWhitelister) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newStrategyWhitelister`|`address`|new address for the `strategyWhitelister`.|


### thirdPartyTransfersForbidden

Returns bool for whether or not `strategy` enables credit transfers. i.e enabling
depositIntoStrategyWithSignature calls or queueing withdrawals to a different address than the staker.


```solidity
function thirdPartyTransfersForbidden(IStrategy strategy) external view returns (bool);
```

### domainSeparator

Getter function for the current EIP-712 domain separator for this contract.

*The domain separator will change in the event of a fork that changes the ChainID.*


```solidity
function domainSeparator() external view returns (bytes32);
```

## Events
### Deposit
Emitted when a new deposit occurs on behalf of `staker`.


```solidity
event Deposit(address staker, IERC20 token, IStrategy strategy, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|Is the staker who is depositing funds into EigenLayer.|
|`token`|`IERC20`|Is the token that `staker` deposited.|
|`strategy`|`IStrategy`|Is the strategy that `staker` has deposited into.|
|`shares`|`uint256`|Is the number of new shares `staker` has been granted in `strategy`.|

### UpdatedThirdPartyTransfersForbidden
Emitted when `thirdPartyTransfersForbidden` is updated for a strategy and value by the owner


```solidity
event UpdatedThirdPartyTransfersForbidden(IStrategy strategy, bool value);
```

### StrategyWhitelisterChanged
Emitted when the `strategyWhitelister` is changed


```solidity
event StrategyWhitelisterChanged(address previousAddress, address newAddress);
```

### StrategyAddedToDepositWhitelist
Emitted when a strategy is added to the approved list of strategies for deposit


```solidity
event StrategyAddedToDepositWhitelist(IStrategy strategy);
```

### StrategyRemovedFromDepositWhitelist
Emitted when a strategy is removed from the approved list of strategies for deposit


```solidity
event StrategyRemovedFromDepositWhitelist(IStrategy strategy);
```

