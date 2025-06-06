# IVault
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v1/interfaces/ISymbioticVault.sol)

**Inherits:**
[IVaultStorage](/src/v1/interfaces/ISymbioticVaultStorage.sol/interface.IVaultStorage.md)


## Functions
### totalStake

Get a total amount of the collateral that can be slashed.


```solidity
function totalStake() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|total amount of the slashable collateral|


### activeBalanceOfAt

Get an active balance for a particular account at a given timestamp using hints.


```solidity
function activeBalanceOfAt(address account, uint48 timestamp, bytes calldata hints) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|account to get the active balance for|
|`timestamp`|`uint48`|time point to get the active balance for the account at|
|`hints`|`bytes`|hints for checkpoints' indexes|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|active balance for the account at the timestamp|


### activeBalanceOf

Get an active balance for a particular account.


```solidity
function activeBalanceOf(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|account to get the active balance for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|active balance for the account|


### withdrawalsOf

Get withdrawals for a particular account at a given epoch (zero if claimed).


```solidity
function withdrawalsOf(uint256 epoch, address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`epoch`|`uint256`|epoch to get the withdrawals for the account at|
|`account`|`address`|account to get the withdrawals for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|withdrawals for the account at the epoch|


### balanceOf

Get a total amount of the collateral that can be slashed for a given account.


```solidity
function balanceOf(address account) external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|total amount of the slashable collateral|


### deposit

Deposit collateral into the vault.


```solidity
function deposit(address onBehalfOf, uint256 amount) external returns (uint256 depositedAmount, uint256 mintedShares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`onBehalfOf`|`address`|account the deposit is made on behalf of|
|`amount`|`uint256`|amount of the collateral to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositedAmount`|`uint256`|amount of the collateral deposited|
|`mintedShares`|`uint256`|amount of the active shares minted|


### withdraw

Withdraw collateral from the vault (it will be claimable after the next epoch).


```solidity
function withdraw(address claimer, uint256 amount) external returns (uint256 burnedShares, uint256 mintedShares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimer`|`address`|account that needs to claim the withdrawal|
|`amount`|`uint256`|amount of the collateral to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`burnedShares`|`uint256`|amount of the active shares burned|
|`mintedShares`|`uint256`|amount of the epoch withdrawal shares minted|


### claim

Claim collateral from the vault.


```solidity
function claim(address recipient, uint256 epoch) external returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|account that receives the collateral|
|`epoch`|`uint256`|epoch to claim the collateral for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of the collateral claimed|


### claimBatch

Claim collateral from the vault for multiple epochs.


```solidity
function claimBatch(address recipient, uint256[] calldata epochs) external returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|account that receives the collateral|
|`epochs`|`uint256[]`|epochs to claim the collateral for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of the collateral claimed|


### onSlash

Slash callback for burning collateral.

*Only the slasher can call this function.*


```solidity
function onSlash(uint256 slashedAmount, uint48 captureTimestamp) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`slashedAmount`|`uint256`|amount to slash|
|`captureTimestamp`|`uint48`|time point when the stake was captured|


### setDepositWhitelist

Enable/disable deposit whitelist.

*Only a DEPOSIT_WHITELIST_SET_ROLE holder can call this function.*


```solidity
function setDepositWhitelist(bool status) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`status`|`bool`|if enabling deposit whitelist|


### setDepositorWhitelistStatus

Set a depositor whitelist status.

*Only a DEPOSITOR_WHITELIST_ROLE holder can call this function.*


```solidity
function setDepositorWhitelistStatus(address account, bool status) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|account for which the whitelist status is set|
|`status`|`bool`|if whitelisting the account|


### setIsDepositLimit

Enable/disable deposit limit.

*Only a IS_DEPOSIT_LIMIT_SET_ROLE holder can call this function.*


```solidity
function setIsDepositLimit(bool status) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`status`|`bool`|if enabling deposit limit|


### setDepositLimit

Set a deposit limit.

*Only a DEPOSIT_LIMIT_SET_ROLE holder can call this function.*


```solidity
function setDepositLimit(uint256 limit) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`limit`|`uint256`|deposit limit (maximum amount of the collateral that can be in the vault simultaneously)|


## Events
### Deposit
Emitted when a deposit is made.


```solidity
event Deposit(address indexed depositor, address indexed onBehalfOf, uint256 amount, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`depositor`|`address`|account that made the deposit|
|`onBehalfOf`|`address`|account the deposit was made on behalf of|
|`amount`|`uint256`|amount of the collateral deposited|
|`shares`|`uint256`|amount of the active shares minted|

### Withdraw
Emitted when a withdrawal is made.


```solidity
event Withdraw(
    address indexed withdrawer, address indexed claimer, uint256 amount, uint256 burnedShares, uint256 mintedShares
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawer`|`address`|account that made the withdrawal|
|`claimer`|`address`|account that needs to claim the withdrawal|
|`amount`|`uint256`|amount of the collateral withdrawn|
|`burnedShares`|`uint256`|amount of the active shares burned|
|`mintedShares`|`uint256`|amount of the epoch withdrawal shares minted|

### Claim
Emitted when a claim is made.


```solidity
event Claim(address indexed claimer, address indexed recipient, uint256 epoch, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimer`|`address`|account that claimed|
|`recipient`|`address`|account that received the collateral|
|`epoch`|`uint256`|epoch the collateral was claimed for|
|`amount`|`uint256`|amount of the collateral claimed|

### ClaimBatch
Emitted when a batch claim is made.


```solidity
event ClaimBatch(address indexed claimer, address indexed recipient, uint256[] epochs, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimer`|`address`|account that claimed|
|`recipient`|`address`|account that received the collateral|
|`epochs`|`uint256[]`|epochs the collateral was claimed for|
|`amount`|`uint256`|amount of the collateral claimed|

### OnSlash
Emitted when a slash happened.


```solidity
event OnSlash(address indexed slasher, uint256 slashedAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`slasher`|`address`|address of the slasher|
|`slashedAmount`|`uint256`|amount of the collateral slashed|

### SetDepositWhitelist
Emitted when a deposit whitelist status is enabled/disabled.


```solidity
event SetDepositWhitelist(bool status);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`status`|`bool`|if enabled deposit whitelist|

### SetDepositorWhitelistStatus
Emitted when a depositor whitelist status is set.


```solidity
event SetDepositorWhitelistStatus(address indexed account, bool status);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|account for which the whitelist status is set|
|`status`|`bool`|if whitelisted the account|

### SetIsDepositLimit
Emitted when a deposit limit status is enabled/disabled.


```solidity
event SetIsDepositLimit(bool status);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`status`|`bool`|if enabled deposit limit|

### SetDepositLimit
Emitted when a deposit limit is set.


```solidity
event SetDepositLimit(uint256 limit);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`limit`|`uint256`|deposit limit (maximum amount of the collateral that can be in the vault simultaneously)|

## Errors
### AlreadyClaimed

```solidity
error AlreadyClaimed();
```

### AlreadySet

```solidity
error AlreadySet();
```

### DepositLimitReached

```solidity
error DepositLimitReached();
```

### InsufficientClaim

```solidity
error InsufficientClaim();
```

### InsufficientDeposit

```solidity
error InsufficientDeposit();
```

### InsufficientWithdrawal

```solidity
error InsufficientWithdrawal();
```

### InvalidAccount

```solidity
error InvalidAccount();
```

### InvalidCaptureEpoch

```solidity
error InvalidCaptureEpoch();
```

### InvalidClaimer

```solidity
error InvalidClaimer();
```

### InvalidCollateral

```solidity
error InvalidCollateral();
```

### InvalidEpoch

```solidity
error InvalidEpoch();
```

### InvalidEpochDuration

```solidity
error InvalidEpochDuration();
```

### InvalidLengthEpochs

```solidity
error InvalidLengthEpochs();
```

### InvalidOnBehalfOf

```solidity
error InvalidOnBehalfOf();
```

### InvalidRecipient

```solidity
error InvalidRecipient();
```

### MissingRoles

```solidity
error MissingRoles();
```

### NoDepositLimit

```solidity
error NoDepositLimit();
```

### NoDepositWhitelist

```solidity
error NoDepositWhitelist();
```

### NotDelegator

```solidity
error NotDelegator();
```

### NotSlasher

```solidity
error NotSlasher();
```

### NotWhitelistedDepositor

```solidity
error NotWhitelistedDepositor();
```

### TooMuchWithdraw

```solidity
error TooMuchWithdraw();
```

## Structs
### InitParams
Initial parameters needed for a vault deployment.


```solidity
struct InitParams {
    address collateral;
    address delegator;
    address slasher;
    address burner;
    uint48 epochDuration;
    bool depositWhitelist;
    bool isDepositLimit;
    uint256 depositLimit;
    address defaultAdminRoleHolder;
    address depositWhitelistSetRoleHolder;
    address depositorWhitelistRoleHolder;
    address isDepositLimitSetRoleHolder;
    address depositLimitSetRoleHolder;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|vault's underlying collateral|
|`delegator`|`address`|vault's delegator to delegate the stake to networks and operators|
|`slasher`|`address`|vault's slasher to provide a slashing mechanism to networks|
|`burner`|`address`|vault's burner to issue debt to (e.g., 0xdEaD or some unwrapper contract)|
|`epochDuration`|`uint48`|duration of the vault epoch (it determines sync points for withdrawals)|
|`depositWhitelist`|`bool`|if enabling deposit whitelist|
|`isDepositLimit`|`bool`|if enabling deposit limit|
|`depositLimit`|`uint256`|deposit limit (maximum amount of the collateral that can be in the vault simultaneously)|
|`defaultAdminRoleHolder`|`address`|address of the initial DEFAULT_ADMIN_ROLE holder|
|`depositWhitelistSetRoleHolder`|`address`|address of the initial DEPOSIT_WHITELIST_SET_ROLE holder|
|`depositorWhitelistRoleHolder`|`address`|address of the initial DEPOSITOR_WHITELIST_ROLE holder|
|`isDepositLimitSetRoleHolder`|`address`|address of the initial IS_DEPOSIT_LIMIT_SET_ROLE holder|
|`depositLimitSetRoleHolder`|`address`|address of the initial DEPOSIT_LIMIT_SET_ROLE holder|

### ActiveBalanceOfHints
Hints for an active balance.


```solidity
struct ActiveBalanceOfHints {
    bytes activeSharesOfHint;
    bytes activeStakeHint;
    bytes activeSharesHint;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`activeSharesOfHint`|`bytes`|hint for the active shares of checkpoint|
|`activeStakeHint`|`bytes`|hint for the active stake checkpoint|
|`activeSharesHint`|`bytes`|hint for the active shares checkpoint|

