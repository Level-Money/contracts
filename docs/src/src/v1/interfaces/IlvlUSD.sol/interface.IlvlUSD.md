# IlvlUSD
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/interfaces/IlvlUSD.sol)

**Inherits:**
IERC20, IERC20Permit, IERC20Metadata


## Functions
### mint


```solidity
function mint(address _to, uint256 _amount) external;
```

### burn


```solidity
function burn(uint256 _amount) external;
```

### burnFrom


```solidity
function burnFrom(address account, uint256 amount) external;
```

### grantRole


```solidity
function grantRole(bytes32 role, address account) external;
```

### setMinter


```solidity
function setMinter(address newMinter) external;
```

### minter


```solidity
function minter() external returns (address);
```

### denylisted


```solidity
function denylisted(address user) external returns (bool);
```

