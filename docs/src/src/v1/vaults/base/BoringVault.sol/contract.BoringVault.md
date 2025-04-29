# BoringVault
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v1/vaults/base/BoringVault.sol)

**Inherits:**
ERC20, Auth, ERC721Holder, ERC1155Holder


## State Variables
### hook
Contract responsbile for implementing `beforeTransfer`.


```solidity
BeforeTransferHook public hook;
```


## Functions
### constructor


```solidity
constructor(address _owner, string memory _name, string memory _symbol, uint8 _decimals)
    ERC20(_name, _symbol, _decimals)
    Auth(_owner, Authority(address(0)));
```

### manage

Allows manager to make an arbitrary function call from this contract.

*Callable by MANAGER_ROLE.*


```solidity
function manage(address target, bytes calldata data, uint256 value)
    external
    requiresAuth
    returns (bytes memory result);
```

### manage

Allows manager to make arbitrary function calls from this contract.

*Callable by MANAGER_ROLE.*


```solidity
function manage(address[] calldata targets, bytes[] calldata data, uint256[] calldata values)
    external
    requiresAuth
    returns (bytes[] memory results);
```

### enter

Allows minter to mint shares, in exchange for assets.

*If assetAmount is zero, no assets are transferred in.*

*Callable by MINTER_ROLE.*


```solidity
function enter(address from, ERC20 asset, uint256 assetAmount, address to, uint256 shareAmount) external requiresAuth;
```

### exit

Allows burner to burn shares, in exchange for assets.

*If assetAmount is zero, no assets are transferred out.*

*Callable by BURNER_ROLE.*


```solidity
function exit(address to, ERC20 asset, uint256 assetAmount, address from, uint256 shareAmount) external requiresAuth;
```

### setBeforeTransferHook

Sets the share locker.

If set to zero address, the share locker logic is disabled.

*Callable by OWNER_ROLE.*


```solidity
function setBeforeTransferHook(address _hook) external requiresAuth;
```

### _callBeforeTransfer

Call `beforeTransferHook` passing in `from` `to`, and `msg.sender`.


```solidity
function _callBeforeTransfer(address from, address to) internal view;
```

### transfer


```solidity
function transfer(address to, uint256 amount) public override returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from, address to, uint256 amount) public override returns (bool);
```

### receive


```solidity
receive() external payable;
```

## Events
### Enter

```solidity
event Enter(address indexed from, address indexed asset, uint256 amount, address indexed to, uint256 shares);
```

### Exit

```solidity
event Exit(address indexed to, address indexed asset, uint256 amount, address indexed from, uint256 shares);
```

