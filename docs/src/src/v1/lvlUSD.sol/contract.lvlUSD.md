# lvlUSD
[Git Source](https://github.com/Level-Money/contracts/blob/cdcafc63c9abdb8c667176cf6dd45d63276ad690/src/v1/lvlUSD.sol)

**Inherits:**
ERC20Burnable, ERC20Permit, [IlvlUSDDefinitions](/src/v1/interfaces/IlvlUSDDefinitions.sol/interface.IlvlUSDDefinitions.md), [SingleAdminAccessControl](/src/v1/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md)

lvlUSD contract


## State Variables
### DENYLIST_MANAGER_ROLE
The role that is allowed to denylist and un-denylist addresses


```solidity
bytes32 private constant DENYLIST_MANAGER_ROLE = keccak256("DENYLIST_MANAGER_ROLE");
```


### denylisted

```solidity
mapping(address => bool) public denylisted;
```


### minter

```solidity
address public minter;
```


## Functions
### constructor


```solidity
constructor(address admin) ERC20("Level USD", "lvlUSD") ERC20Permit("Level USD");
```

### notOwner


```solidity
modifier notOwner(address account);
```

### setMinter


```solidity
function setMinter(address newMinter) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### mint


```solidity
function mint(address to, uint256 amount) external;
```

### renounceRole

*Remove renounce role access from AccessControl, to prevent users from resigning from roles.*


```solidity
function renounceRole(bytes32, address) public virtual override;
```

### _beforeTokenTransfer

*Hook that is called before any transfer of tokens. This includes
minting and burning. Disables transfers from or to of addresses with the DENYLISTED_ROLE role.*


```solidity
function _beforeTokenTransfer(address from, address to, uint256) internal virtual override;
```

### addToDenylist

Allows the owner (DEFAULT_ADMIN_ROLE) and denylist managers to denylist addresses.


```solidity
function addToDenylist(address target) external onlyRole(DENYLIST_MANAGER_ROLE) notOwner(target);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address to denylist.|


### removeFromDenylist

Allows denylist managers to remove addresses from the denylist.


```solidity
function removeFromDenylist(address target) external onlyRole(DENYLIST_MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address to remove from the denylist.|


