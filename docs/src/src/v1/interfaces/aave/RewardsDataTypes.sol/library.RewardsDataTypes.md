# RewardsDataTypes
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v1/interfaces/aave/RewardsDataTypes.sol)


## Structs
### RewardsConfigInput

```solidity
struct RewardsConfigInput {
    uint88 emissionPerSecond;
    uint256 totalSupply;
    uint32 distributionEnd;
    address asset;
    address reward;
    ITransferStrategyBase transferStrategy;
    IEACAggregatorProxy rewardOracle;
}
```

### UserAssetBalance

```solidity
struct UserAssetBalance {
    address asset;
    uint256 userBalance;
    uint256 totalSupply;
}
```

### UserData

```solidity
struct UserData {
    uint104 index;
    uint128 accrued;
}
```

### RewardData

```solidity
struct RewardData {
    uint104 index;
    uint88 emissionPerSecond;
    uint32 lastUpdateTimestamp;
    uint32 distributionEnd;
    mapping(address => UserData) usersData;
}
```

### AssetData

```solidity
struct AssetData {
    mapping(address => RewardData) rewards;
    mapping(uint128 => address) availableRewards;
    uint128 availableRewardsCount;
    uint8 decimals;
}
```

