# IMorphoBase
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/interfaces/morpho/IMorpho.sol)

*This interface is used for factorizing IMorphoStaticTyping and IMorpho.*

*Consider using the IMorpho interface instead of this one.*


## Functions
### DOMAIN_SEPARATOR

The EIP-712 domain separator.

*Warning: Every EIP-712 signed message based on this domain separator can be reused on chains sharing the
same chain id and on forks because the domain separator would be the same.*


```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32);
```

### owner

The owner of the contract.

*It has the power to change the owner.*

*It has the power to set fees on markets and set the fee recipient.*

*It has the power to enable but not disable IRMs and LLTVs.*


```solidity
function owner() external view returns (address);
```

### feeRecipient

The fee recipient of all markets.

*The recipient receives the fees of a given market through a supply position on that market.*


```solidity
function feeRecipient() external view returns (address);
```

### isIrmEnabled

Whether the `irm` is enabled.


```solidity
function isIrmEnabled(address irm) external view returns (bool);
```

### isLltvEnabled

Whether the `lltv` is enabled.


```solidity
function isLltvEnabled(uint256 lltv) external view returns (bool);
```

### isAuthorized

Whether `authorized` is authorized to modify `authorizer`'s position on all markets.

*Anyone is authorized to modify their own positions, regardless of this variable.*


```solidity
function isAuthorized(address authorizer, address authorized) external view returns (bool);
```

### nonce

The `authorizer`'s current nonce. Used to prevent replay attacks with EIP-712 signatures.


```solidity
function nonce(address authorizer) external view returns (uint256);
```

### setOwner

Sets `newOwner` as `owner` of the contract.

*Warning: No two-step transfer ownership.*

*Warning: The owner can be set to the zero address.*


```solidity
function setOwner(address newOwner) external;
```

### enableIrm

Enables `irm` as a possible IRM for market creation.

*Warning: It is not possible to disable an IRM.*


```solidity
function enableIrm(address irm) external;
```

### enableLltv

Enables `lltv` as a possible LLTV for market creation.

*Warning: It is not possible to disable a LLTV.*


```solidity
function enableLltv(uint256 lltv) external;
```

### setFee

Sets the `newFee` for the given market `marketParams`.

*Warning: The recipient can be the zero address.*


```solidity
function setFee(MarketParams memory marketParams, uint256 newFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`||
|`newFee`|`uint256`|The new fee, scaled by WAD.|


### setFeeRecipient

Sets `newFeeRecipient` as `feeRecipient` of the fee.

*Warning: If the fee recipient is set to the zero address, fees will accrue there and will be lost.*

*Modifying the fee recipient will allow the new recipient to claim any pending fees not yet accrued. To
ensure that the current recipient receives all due fees, accrue interest manually prior to making any changes.*


```solidity
function setFeeRecipient(address newFeeRecipient) external;
```

### createMarket

Creates the market `marketParams`.

*Here is the list of assumptions on the market's dependencies (tokens, IRM and oracle) that guarantees
Morpho behaves as expected:
- The token should be ERC-20 compliant, except that it can omit return values on `transfer` and `transferFrom`.
- The token balance of Morpho should only decrease on `transfer` and `transferFrom`. In particular, tokens with
burn functions are not supported.
- The token should not re-enter Morpho on `transfer` nor `transferFrom`.
- The token balance of the sender (resp. receiver) should decrease (resp. increase) by exactly the given amount
on `transfer` and `transferFrom`. In particular, tokens with fees on transfer are not supported.
- The IRM should not re-enter Morpho.
- The oracle should return a price with the correct scaling.*

*Here is a list of assumptions on the market's dependencies which, if broken, could break Morpho's liveness
properties (funds could get stuck):
- The token should not revert on `transfer` and `transferFrom` if balances and approvals are right.
- The amount of assets supplied and borrowed should not go above ~1e35 (otherwise the computation of
`toSharesUp` and `toSharesDown` can overflow).
- The IRM should not revert on `borrowRate`.
- The IRM should not return a very high borrow rate (otherwise the computation of `interest` in
`_accrueInterest` can overflow).
- The oracle should not revert `price`.
- The oracle should not return a very high price (otherwise the computation of `maxBorrow` in `_isHealthy` or of
`assetsRepaid` in `liquidate` can overflow).*

*The borrow share price of a market with less than 1e4 assets borrowed can be decreased by manipulations, to
the point where `totalBorrowShares` is very large and borrowing overflows.*


```solidity
function createMarket(MarketParams memory marketParams) external;
```

### supply

Supplies `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's
`onMorphoSupply` function with the given `data`.

*Either `assets` or `shares` should be zero. Most use cases should rely on `assets` as an input so the
caller is guaranteed to have `assets` tokens pulled from their balance, but the possibility to mint a specific
amount of shares is given for full compatibility and precision.*

*Supplying a large amount can revert for overflow.*

*Supplying an amount of shares may lead to supply more or fewer assets than expected due to slippage.
Consider using the `assets` parameter to avoid this.*


```solidity
function supply(MarketParams memory marketParams, uint256 assets, uint256 shares, address onBehalf, bytes memory data)
    external
    returns (uint256 assetsSupplied, uint256 sharesSupplied);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`|The market to supply assets to.|
|`assets`|`uint256`|The amount of assets to supply.|
|`shares`|`uint256`|The amount of shares to mint.|
|`onBehalf`|`address`|The address that will own the increased supply position.|
|`data`|`bytes`|Arbitrary data to pass to the `onMorphoSupply` callback. Pass empty data if not needed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetsSupplied`|`uint256`|The amount of assets supplied.|
|`sharesSupplied`|`uint256`|The amount of shares minted.|


### withdraw

Withdraws `assets` or `shares` on behalf of `onBehalf` and sends the assets to `receiver`.

*Either `assets` or `shares` should be zero. To withdraw max, pass the `shares`'s balance of `onBehalf`.*

*`msg.sender` must be authorized to manage `onBehalf`'s positions.*

*Withdrawing an amount corresponding to more shares than supplied will revert for underflow.*

*It is advised to use the `shares` input when withdrawing the full position to avoid reverts due to
conversion roundings between shares and assets.*


```solidity
function withdraw(MarketParams memory marketParams, uint256 assets, uint256 shares, address onBehalf, address receiver)
    external
    returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`|The market to withdraw assets from.|
|`assets`|`uint256`|The amount of assets to withdraw.|
|`shares`|`uint256`|The amount of shares to burn.|
|`onBehalf`|`address`|The address of the owner of the supply position.|
|`receiver`|`address`|The address that will receive the withdrawn assets.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetsWithdrawn`|`uint256`|The amount of assets withdrawn.|
|`sharesWithdrawn`|`uint256`|The amount of shares burned.|


### borrow

Borrows `assets` or `shares` on behalf of `onBehalf` and sends the assets to `receiver`.

*Either `assets` or `shares` should be zero. Most use cases should rely on `assets` as an input so the
caller is guaranteed to borrow `assets` of tokens, but the possibility to mint a specific amount of shares is
given for full compatibility and precision.*

*`msg.sender` must be authorized to manage `onBehalf`'s positions.*

*Borrowing a large amount can revert for overflow.*

*Borrowing an amount of shares may lead to borrow fewer assets than expected due to slippage.
Consider using the `assets` parameter to avoid this.*


```solidity
function borrow(MarketParams memory marketParams, uint256 assets, uint256 shares, address onBehalf, address receiver)
    external
    returns (uint256 assetsBorrowed, uint256 sharesBorrowed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`|The market to borrow assets from.|
|`assets`|`uint256`|The amount of assets to borrow.|
|`shares`|`uint256`|The amount of shares to mint.|
|`onBehalf`|`address`|The address that will own the increased borrow position.|
|`receiver`|`address`|The address that will receive the borrowed assets.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetsBorrowed`|`uint256`|The amount of assets borrowed.|
|`sharesBorrowed`|`uint256`|The amount of shares minted.|


### repay

Repays `assets` or `shares` on behalf of `onBehalf`, optionally calling back the caller's
`onMorphoRepay` function with the given `data`.

*Either `assets` or `shares` should be zero. To repay max, pass the `shares`'s balance of `onBehalf`.*

*Repaying an amount corresponding to more shares than borrowed will revert for underflow.*

*It is advised to use the `shares` input when repaying the full position to avoid reverts due to conversion
roundings between shares and assets.*

*An attacker can front-run a repay with a small repay making the transaction revert for underflow.*


```solidity
function repay(MarketParams memory marketParams, uint256 assets, uint256 shares, address onBehalf, bytes memory data)
    external
    returns (uint256 assetsRepaid, uint256 sharesRepaid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`|The market to repay assets to.|
|`assets`|`uint256`|The amount of assets to repay.|
|`shares`|`uint256`|The amount of shares to burn.|
|`onBehalf`|`address`|The address of the owner of the debt position.|
|`data`|`bytes`|Arbitrary data to pass to the `onMorphoRepay` callback. Pass empty data if not needed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetsRepaid`|`uint256`|The amount of assets repaid.|
|`sharesRepaid`|`uint256`|The amount of shares burned.|


### supplyCollateral

Supplies `assets` of collateral on behalf of `onBehalf`, optionally calling back the caller's
`onMorphoSupplyCollateral` function with the given `data`.

*Interest are not accrued since it's not required and it saves gas.*

*Supplying a large amount can revert for overflow.*


```solidity
function supplyCollateral(MarketParams memory marketParams, uint256 assets, address onBehalf, bytes memory data)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`|The market to supply collateral to.|
|`assets`|`uint256`|The amount of collateral to supply.|
|`onBehalf`|`address`|The address that will own the increased collateral position.|
|`data`|`bytes`|Arbitrary data to pass to the `onMorphoSupplyCollateral` callback. Pass empty data if not needed.|


### withdrawCollateral

Withdraws `assets` of collateral on behalf of `onBehalf` and sends the assets to `receiver`.

*`msg.sender` must be authorized to manage `onBehalf`'s positions.*

*Withdrawing an amount corresponding to more collateral than supplied will revert for underflow.*


```solidity
function withdrawCollateral(MarketParams memory marketParams, uint256 assets, address onBehalf, address receiver)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`|The market to withdraw collateral from.|
|`assets`|`uint256`|The amount of collateral to withdraw.|
|`onBehalf`|`address`|The address of the owner of the collateral position.|
|`receiver`|`address`|The address that will receive the collateral assets.|


### liquidate

Liquidates the given `repaidShares` of debt asset or seize the given `seizedAssets` of collateral on the
given market `marketParams` of the given `borrower`'s position, optionally calling back the caller's
`onMorphoLiquidate` function with the given `data`.

*Either `seizedAssets` or `repaidShares` should be zero.*

*Seizing more than the collateral balance will underflow and revert without any error message.*

*Repaying more than the borrow balance will underflow and revert without any error message.*

*An attacker can front-run a liquidation with a small repay making the transaction revert for underflow.*


```solidity
function liquidate(
    MarketParams memory marketParams,
    address borrower,
    uint256 seizedAssets,
    uint256 repaidShares,
    bytes memory data
) external returns (uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`marketParams`|`MarketParams`|The market of the position.|
|`borrower`|`address`|The owner of the position.|
|`seizedAssets`|`uint256`|The amount of collateral to seize.|
|`repaidShares`|`uint256`|The amount of shares to repay.|
|`data`|`bytes`|Arbitrary data to pass to the `onMorphoLiquidate` callback. Pass empty data if not needed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of assets seized.|
|`<none>`|`uint256`|The amount of assets repaid.|


### flashLoan

Executes a flash loan.

*Flash loans have access to the whole balance of the contract (the liquidity and deposited collateral of all
markets combined, plus donations).*

*Warning: Not ERC-3156 compliant but compatibility is easily reached:
- `flashFee` is zero.
- `maxFlashLoan` is the token's balance of this contract.
- The receiver of `assets` is the caller.*


```solidity
function flashLoan(address token, uint256 assets, bytes calldata data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to flash loan.|
|`assets`|`uint256`|The amount of assets to flash loan.|
|`data`|`bytes`|Arbitrary data to pass to the `onMorphoFlashLoan` callback.|


### setAuthorization

Sets the authorization for `authorized` to manage `msg.sender`'s positions.


```solidity
function setAuthorization(address authorized, bool newIsAuthorized) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`authorized`|`address`|The authorized address.|
|`newIsAuthorized`|`bool`|The new authorization status.|


### setAuthorizationWithSig

Sets the authorization for `authorization.authorized` to manage `authorization.authorizer`'s positions.

*Warning: Reverts if the signature has already been submitted.*

*The signature is malleable, but it has no impact on the security here.*

*The nonce is passed as argument to be able to revert with a different error message.*


```solidity
function setAuthorizationWithSig(Authorization calldata authorization, Signature calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`authorization`|`Authorization`|The `Authorization` struct.|
|`signature`|`Signature`|The signature.|


### accrueInterest

Accrues interest for the given market `marketParams`.


```solidity
function accrueInterest(MarketParams memory marketParams) external;
```

### extSloads

Returns the data stored on the different `slots`.


```solidity
function extSloads(bytes32[] memory slots) external view returns (bytes32[] memory);
```

