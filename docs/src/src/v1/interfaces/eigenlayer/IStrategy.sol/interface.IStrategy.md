# IStrategy
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/interfaces/eigenlayer/IStrategy.sol)

**Author:**
Layr Labs, Inc.

Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service

Custom `Strategy` implementations may expand extensively on this interface.


## Functions
### deposit

Used to deposit tokens into this Strategy

*This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
`depositIntoStrategy` function, and individual share balances are recorded in the strategyManager as well.*


```solidity
function deposit(IERC20 token, uint256 amount) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`IERC20`|is the ERC20 token being deposited|
|`amount`|`uint256`|is the amount of token being deposited|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|newShares is the number of new shares issued at the current exchange ratio.|


### withdraw

Used to withdraw tokens from this Strategy, to the `recipient`'s address

*This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
other functions, and individual share balances are recorded in the strategyManager as well.*


```solidity
function withdraw(address recipient, IERC20 token, uint256 amountShares) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|is the address to receive the withdrawn funds|
|`token`|`IERC20`|is the ERC20 token being transferred out|
|`amountShares`|`uint256`|is the amount of shares being withdrawn|


### sharesToUnderlying

Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.

In contrast to `sharesToUnderlyingView`, this function **may** make state modifications

*Implementation for these functions in particular may vary significantly for different strategies*


```solidity
function sharesToUnderlying(uint256 amountShares) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountShares`|`uint256`|is the amount of shares to calculate its conversion into the underlying token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of underlying tokens corresponding to the input `amountShares`|


### underlyingToShares

Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.

In contrast to `underlyingToSharesView`, this function **may** make state modifications

*Implementation for these functions in particular may vary significantly for different strategies*


```solidity
function underlyingToShares(uint256 amountUnderlying) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountUnderlying`|`uint256`|is the amount of `underlyingToken` to calculate its conversion into strategy shares|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of underlying tokens corresponding to the input `amountShares`|


### userUnderlying

convenience function for fetching the current underlying value of all of the `user`'s shares in
this strategy. In contrast to `userUnderlyingView`, this function **may** make state modifications


```solidity
function userUnderlying(address user) external returns (uint256);
```

### shares

convenience function for fetching the current total shares of `user` in this strategy, by
querying the `strategyManager` contract


```solidity
function shares(address user) external view returns (uint256);
```

### sharesToUnderlyingView

Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.

In contrast to `sharesToUnderlying`, this function guarantees no state modifications

*Implementation for these functions in particular may vary significantly for different strategies*


```solidity
function sharesToUnderlyingView(uint256 amountShares) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountShares`|`uint256`|is the amount of shares to calculate its conversion into the underlying token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of shares corresponding to the input `amountUnderlying`|


### underlyingToSharesView

Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.

In contrast to `underlyingToShares`, this function guarantees no state modifications

*Implementation for these functions in particular may vary significantly for different strategies*


```solidity
function underlyingToSharesView(uint256 amountUnderlying) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountUnderlying`|`uint256`|is the amount of `underlyingToken` to calculate its conversion into strategy shares|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of shares corresponding to the input `amountUnderlying`|


### userUnderlyingView

convenience function for fetching the current underlying value of all of the `user`'s shares in
this strategy. In contrast to `userUnderlying`, this function guarantees no state modifications


```solidity
function userUnderlyingView(address user) external view returns (uint256);
```

### underlyingToken

The underlying token for shares in this Strategy


```solidity
function underlyingToken() external view returns (IERC20);
```

### totalShares

The total number of extant shares in this Strategy


```solidity
function totalShares() external view returns (uint256);
```

### explanation

Returns either a brief string explaining the strategy's goal & purpose, or a link to metadata that explains in more detail.


```solidity
function explanation() external view returns (string memory);
```

## Events
### ExchangeRateEmitted
Used to emit an event for the exchange rate between 1 share and underlying token in a strategy contract

*Tokens that do not have 18 decimals must have offchain services scale the exchange rate by the proper magnitude*


```solidity
event ExchangeRateEmitted(uint256 rate);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rate`|`uint256`|is the exchange rate in wad 18 decimals|

### StrategyTokenSet
Used to emit the underlying token and its decimals on strategy creation

token


```solidity
event StrategyTokenSet(IERC20 token, uint8 decimals);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`IERC20`|is the ERC20 token of the strategy|
|`decimals`|`uint8`|are the decimals of the ERC20 token in the strategy|

