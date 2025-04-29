# IVault
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v1/interfaces/IKarakVault.sol)

**Inherits:**
[IKarakBaseVault](/src/v1/interfaces/IKarakBaseVault.sol/interface.IKarakBaseVault.md)


## Functions
### deposit


```solidity
function deposit(uint256 assets, address to) external returns (uint256 shares);
```

### deposit


```solidity
function deposit(uint256 assets, address to, uint256 minSharesOut) external returns (uint256 shares);
```

### mint


```solidity
function mint(uint256 shares, address to) external returns (uint256 assets);
```

### startRedeem


```solidity
function startRedeem(uint256 shares, address withdrawer) external returns (bytes32 withdrawalKey);
```

### finishRedeem


```solidity
function finishRedeem(bytes32 withdrawalKey) external;
```

### owner


```solidity
function owner() external view returns (address);
```

### getNextWithdrawNonce


```solidity
function getNextWithdrawNonce(address staker) external view returns (uint256);
```

### isWithdrawalPending


```solidity
function isWithdrawalPending(address staker, uint256 _withdrawNonce) external view returns (bool);
```

### extSloads


```solidity
function extSloads(bytes32[] calldata slots) external view returns (bytes32[] memory res);
```

