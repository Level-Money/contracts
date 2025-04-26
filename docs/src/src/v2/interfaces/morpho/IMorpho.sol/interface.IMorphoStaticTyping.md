# IMorphoStaticTyping
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v2/interfaces/morpho/IMorpho.sol)

**Inherits:**
[IMorphoBase](/src/v2/interfaces/morpho/IMorpho.sol/interface.IMorphoBase.md)

*This interface is inherited by Morpho so that function signatures are checked by the compiler.*

*Consider using the IMorpho interface instead of this one.*


## Functions
### position

The state of the position of `user` on the market corresponding to `id`.

*Warning: For `feeRecipient`, `supplyShares` does not contain the accrued shares since the last interest
accrual.*


```solidity
function position(Id id, address user)
    external
    view
    returns (uint256 supplyShares, uint128 borrowShares, uint128 collateral);
```

### market

The state of the market corresponding to `id`.

*Warning: `totalSupplyAssets` does not contain the accrued interest since the last interest accrual.*

*Warning: `totalBorrowAssets` does not contain the accrued interest since the last interest accrual.*

*Warning: `totalSupplyShares` does not contain the accrued shares by `feeRecipient` since the last interest
accrual.*


```solidity
function market(Id id)
    external
    view
    returns (
        uint128 totalSupplyAssets,
        uint128 totalSupplyShares,
        uint128 totalBorrowAssets,
        uint128 totalBorrowShares,
        uint128 lastUpdate,
        uint128 fee
    );
```

### idToMarketParams

The market params corresponding to `id`.

*This mapping is not used in Morpho. It is there to enable reducing the cost associated to calldata on layer
2s by creating a wrapper contract with functions that take `id` as input instead of `marketParams`.*


```solidity
function idToMarketParams(Id id)
    external
    view
    returns (address loanToken, address collateralToken, address oracle, address irm, uint256 lltv);
```

