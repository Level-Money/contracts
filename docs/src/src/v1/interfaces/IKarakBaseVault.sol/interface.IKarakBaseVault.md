# IKarakBaseVault
[Git Source](https://github.com/Level-Money/contracts/blob/6210538f7de83f92b07f38679d7d19520c984a03/src/v1/interfaces/IKarakBaseVault.sol)


## Functions
### initialize


```solidity
function initialize(
    address _owner,
    address _operator,
    address _depositToken,
    string memory _name,
    string memory _symbol,
    bytes memory _extraData
) external;
```

### slashAssets


```solidity
function slashAssets(uint256 slashPercentageWad, address slashingHandler) external returns (uint256 transferAmount);
```

### pause


```solidity
function pause(uint256 map) external;
```

### unpause


```solidity
function unpause(uint256 map) external;
```

### totalAssets


```solidity
function totalAssets() external view returns (uint256);
```

### name


```solidity
function name() external view returns (string memory);
```

### symbol


```solidity
function symbol() external view returns (string memory);
```

### decimals


```solidity
function decimals() external view returns (uint8);
```

### asset


```solidity
function asset() external view returns (address);
```

