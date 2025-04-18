# IStrategyFactory
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v1/interfaces/eigenlayer/IStrategyFactory.sol)

**Author:**
Layr Labs, Inc.

Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service

*This may not be compatible with non-standard ERC20 tokens. Caution is warranted.*


## Functions
### deployedStrategies

Mapping token => Strategy contract for the token
The strategies in this mapping are deployed by the StrategyFactory.
The factory can only deploy a single strategy per token address
These strategies MIGHT not be whitelisted in the StrategyManager,
though deployNewStrategy does whitelist by default.
These strategies MIGHT not be the only strategy for the underlying token
as additional strategies can be whitelisted by the owner of the factory.


```solidity
function deployedStrategies(IERC20 token) external view returns (IStrategy);
```

### deployNewStrategy

Deploy a new strategyBeacon contract for the ERC20 token.

*A strategy contract must not yet exist for the token.
$dev Immense caution is warranted for non-standard ERC20 tokens, particularly "reentrant" tokens
like those that conform to ERC777.*


```solidity
function deployNewStrategy(IERC20 token) external returns (IStrategy newStrategy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`IERC20`|the token to deploy a strategy for|


### whitelistStrategies

Owner-only function to pass through a call to `StrategyManager.addStrategiesToDepositWhitelist`


```solidity
function whitelistStrategies(
    IStrategy[] calldata strategiesToWhitelist,
    bool[] calldata thirdPartyTransfersForbiddenValues
) external;
```

### setThirdPartyTransfersForbidden

Owner-only function to pass through a call to `StrategyManager.setThirdPartyTransfersForbidden`


```solidity
function setThirdPartyTransfersForbidden(IStrategy strategy, bool value) external;
```

### removeStrategiesFromWhitelist

Owner-only function to pass through a call to `StrategyManager.removeStrategiesFromDepositWhitelist`


```solidity
function removeStrategiesFromWhitelist(IStrategy[] calldata strategiesToRemoveFromWhitelist) external;
```

## Events
### TokenBlacklisted

```solidity
event TokenBlacklisted(IERC20 token);
```

### StrategySetForToken
Emitted whenever a slot is set in the `tokenStrategy` mapping


```solidity
event StrategySetForToken(IERC20 token, IStrategy strategy);
```

