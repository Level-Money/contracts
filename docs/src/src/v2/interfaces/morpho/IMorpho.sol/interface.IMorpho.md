# IMorpho
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v2/interfaces/morpho/IMorpho.sol)

**Inherits:**
[IMorphoBase](/src/v2/interfaces/morpho/IMorpho.sol/interface.IMorphoBase.md)

**Author:**
Morpho Labs

*Use this interface for Morpho to have access to all the functions with the appropriate function signatures.*

**Note:**
contact: security@morpho.org


## Functions
### position

The state of the position of `user` on the market corresponding to `id`.

*Warning: For `feeRecipient`, `p.supplyShares` does not contain the accrued shares since the last interest
accrual.*


```solidity
function position(Id id, address user) external view returns (Position memory p);
```

### market

The state of the market corresponding to `id`.

*Warning: `m.totalSupplyAssets` does not contain the accrued interest since the last interest accrual.*

*Warning: `m.totalBorrowAssets` does not contain the accrued interest since the last interest accrual.*

*Warning: `m.totalSupplyShares` does not contain the accrued shares by `feeRecipient` since the last
interest accrual.*


```solidity
function market(Id id) external view returns (Market memory m);
```

### idToMarketParams

The market params corresponding to `id`.

*This mapping is not used in Morpho. It is there to enable reducing the cost associated to calldata on layer
2s by creating a wrapper contract with functions that take `id` as input instead of `marketParams`.*


```solidity
function idToMarketParams(Id id) external view returns (MarketParams memory);
```

