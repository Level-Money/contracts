# IMetaMorphoBase
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v2/interfaces/morpho/IMetaMorpho.sol)

*This interface is used for factorizing IMetaMorphoStaticTyping and IMetaMorpho.*

*Consider using the IMetaMorpho interface instead of this one.*


## Functions
### MORPHO

The address of the Morpho contract.


```solidity
function MORPHO() external view returns (IMorpho);
```

### DECIMALS_OFFSET


```solidity
function DECIMALS_OFFSET() external view returns (uint8);
```

### curator

The address of the curator.


```solidity
function curator() external view returns (address);
```

### isAllocator

Stores whether an address is an allocator or not.


```solidity
function isAllocator(address target) external view returns (bool);
```

### guardian

The current guardian. Can be set even without the timelock set.


```solidity
function guardian() external view returns (address);
```

### fee

The current fee.


```solidity
function fee() external view returns (uint96);
```

### feeRecipient

The fee recipient.


```solidity
function feeRecipient() external view returns (address);
```

### skimRecipient

The skim recipient.


```solidity
function skimRecipient() external view returns (address);
```

### timelock

The current timelock.


```solidity
function timelock() external view returns (uint256);
```

### supplyQueue

*Stores the order of markets on which liquidity is supplied upon deposit.*

*Can contain any market. A market is skipped as soon as its supply cap is reached.*


```solidity
function supplyQueue(uint256) external view returns (Id);
```

### supplyQueueLength

Returns the length of the supply queue.


```solidity
function supplyQueueLength() external view returns (uint256);
```

### withdrawQueue

*Stores the order of markets from which liquidity is withdrawn upon withdrawal.*

*Always contain all non-zero cap markets as well as all markets on which the vault supplies liquidity,
without duplicate.*


```solidity
function withdrawQueue(uint256) external view returns (Id);
```

### withdrawQueueLength

Returns the length of the withdraw queue.


```solidity
function withdrawQueueLength() external view returns (uint256);
```

### lastTotalAssets

Stores the total assets managed by this vault when the fee was last accrued.

*May be greater than `totalAssets()` due to removal of markets with non-zero supply or socialized bad debt.
This difference will decrease the fee accrued until one of the functions updating `lastTotalAssets` is
triggered (deposit/mint/withdraw/redeem/setFee/setFeeRecipient).*


```solidity
function lastTotalAssets() external view returns (uint256);
```

### submitTimelock

Submits a `newTimelock`.

*Warning: Reverts if a timelock is already pending. Revoke the pending timelock to overwrite it.*

*In case the new timelock is higher than the current one, the timelock is set immediately.*


```solidity
function submitTimelock(uint256 newTimelock) external;
```

### acceptTimelock

Accepts the pending timelock.


```solidity
function acceptTimelock() external;
```

### revokePendingTimelock

Revokes the pending timelock.

*Does not revert if there is no pending timelock.*


```solidity
function revokePendingTimelock() external;
```

### submitCap

Submits a `newSupplyCap` for the market defined by `marketParams`.

*Warning: Reverts if a cap is already pending. Revoke the pending cap to overwrite it.*

*Warning: Reverts if a market removal is pending.*

*In case the new cap is lower than the current one, the cap is set immediately.*


```solidity
function submitCap(MarketParams memory marketParams, uint256 newSupplyCap) external;
```

### acceptCap

Accepts the pending cap of the market defined by `marketParams`.


```solidity
function acceptCap(MarketParams memory marketParams) external;
```

### revokePendingCap

Revokes the pending cap of the market defined by `id`.

*Does not revert if there is no pending cap.*


```solidity
function revokePendingCap(Id id) external;
```

### submitMarketRemoval

Submits a forced market removal from the vault, eventually losing all funds supplied to the market.

This forced removal is expected to be used as an emergency process in case a market constantly reverts.
To softly remove a sane market, the curator role is expected to bundle a reallocation that empties the market
first (using `reallocate`), followed by the removal of the market (using `updateWithdrawQueue`).

*Warning: Removing a market with non-zero supply will instantly impact the vault's price per share.*

*Warning: Reverts for non-zero cap or if there is a pending cap. Successfully submitting a zero cap will
prevent such reverts.*


```solidity
function submitMarketRemoval(MarketParams memory marketParams) external;
```

### revokePendingMarketRemoval

Revokes the pending removal of the market defined by `id`.

*Does not revert if there is no pending market removal.*


```solidity
function revokePendingMarketRemoval(Id id) external;
```

### submitGuardian

Submits a `newGuardian`.

Warning: a malicious guardian could disrupt the vault's operation, and would have the power to revoke
any pending guardian.

*In case there is no guardian, the gardian is set immediately.*

*Warning: Submitting a gardian will overwrite the current pending gardian.*


```solidity
function submitGuardian(address newGuardian) external;
```

### acceptGuardian

Accepts the pending guardian.


```solidity
function acceptGuardian() external;
```

### revokePendingGuardian

Revokes the pending guardian.


```solidity
function revokePendingGuardian() external;
```

### skim

Skims the vault `token` balance to `skimRecipient`.


```solidity
function skim(address) external;
```

### setIsAllocator

Sets `newAllocator` as an allocator or not (`newIsAllocator`).


```solidity
function setIsAllocator(address newAllocator, bool newIsAllocator) external;
```

### setCurator

Sets `curator` to `newCurator`.


```solidity
function setCurator(address newCurator) external;
```

### setFee

Sets the `fee` to `newFee`.


```solidity
function setFee(uint256 newFee) external;
```

### setFeeRecipient

Sets `feeRecipient` to `newFeeRecipient`.


```solidity
function setFeeRecipient(address newFeeRecipient) external;
```

### setSkimRecipient

Sets `skimRecipient` to `newSkimRecipient`.


```solidity
function setSkimRecipient(address newSkimRecipient) external;
```

### setSupplyQueue

Sets `supplyQueue` to `newSupplyQueue`.


```solidity
function setSupplyQueue(Id[] calldata newSupplyQueue) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newSupplyQueue`|`Id[]`|is an array of enabled markets, and can contain duplicate markets, but it would only increase the cost of depositing to the vault.|


### updateWithdrawQueue

Updates the withdraw queue. Some markets can be removed, but no market can be added.

Removing a market requires the vault to have 0 supply on it, or to have previously submitted a removal
for this market (with the function `submitMarketRemoval`).

Warning: Anyone can supply on behalf of the vault so the call to `updateWithdrawQueue` that expects a
market to be empty can be griefed by a front-run. To circumvent this, the allocator can simply bundle a
reallocation that withdraws max from this market with a call to `updateWithdrawQueue`.

*Warning: Removing a market with supply will decrease the fee accrued until one of the functions updating
`lastTotalAssets` is triggered (deposit/mint/withdraw/redeem/setFee/setFeeRecipient).*

*Warning: `updateWithdrawQueue` is not idempotent. Submitting twice the same tx will change the queue twice.*


```solidity
function updateWithdrawQueue(uint256[] calldata indexes) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`indexes`|`uint256[]`|The indexes of each market in the previous withdraw queue, in the new withdraw queue's order.|


### reallocate

Reallocates the vault's liquidity so as to reach a given allocation of assets on each given market.

*The behavior of the reallocation can be altered by state changes, including:
- Deposits on the vault that supplies to markets that are expected to be supplied to during reallocation.
- Withdrawals from the vault that withdraws from markets that are expected to be withdrawn from during
reallocation.
- Donations to the vault on markets that are expected to be supplied to during reallocation.
- Withdrawals from markets that are expected to be withdrawn from during reallocation.*

*Sender is expected to pass `assets = type(uint256).max` with the last MarketAllocation of `allocations` to
supply all the remaining withdrawn liquidity, which would ensure that `totalWithdrawn` = `totalSupplied`.*

*A supply in a reallocation step will make the reallocation revert if the amount is greater than the net
amount from previous steps (i.e. total withdrawn minus total supplied).*


```solidity
function reallocate(MarketAllocation[] calldata allocations) external;
```

