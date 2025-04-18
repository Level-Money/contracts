# WrappedRebasingERC20
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v1/WrappedRebasingERC20.sol)

**Inherits:**
ERC20, [SingleAdminAccessControl](/src/v1/auth/v5/SingleAdminAccessControl.sol/abstract.SingleAdminAccessControl.md)

*Extension of the ERC-20 token contract to support token wrapping.
Users can deposit and withdraw "underlying tokens" and receive a matching number of "wrapped tokens". This is useful
in conjunction with other modules. For example, combining this wrapping mechanism with {ERC20Votes} will allow the
wrapping of an existing "basic" ERC-20 into a governance token.
WARNING: Any mechanism in which the underlying token changes the {balanceOf} of an account without an explicit transfer
may desynchronize this contract's supply and its underlying balance. Please exercise caution when wrapping tokens that
may undercollateralize the wrapper (i.e. wrapper's total supply is higher than its underlying balance). See {claimAllRewards}
for recovering value accrued to the wrapper.*


## State Variables
### _underlying

```solidity
IERC20 private immutable _underlying;
```


### RECOVERER_ROLE

```solidity
bytes32 public RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
```


## Functions
### constructor


```solidity
constructor(IERC20 underlyingToken, string memory name, string memory symbol) ERC20(name, symbol);
```

### decimals

*See [ERC20-decimals](/src/v1/interfaces/IKarakBaseVault.sol/interface.IKarakBaseVault.md#decimals).*


```solidity
function decimals() public view virtual override returns (uint8);
```

### underlying

*Returns the address of the underlying ERC-20 token that is being wrapped.*


```solidity
function underlying() public view returns (IERC20);
```

### depositFor

*Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.*


```solidity
function depositFor(address account, uint256 value) public virtual returns (bool);
```

### withdrawTo

*Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.*


```solidity
function withdrawTo(address account, uint256 value) public virtual returns (bool);
```

### recoverUnderlying

*Mint wrapped token to cover any underlyingTokens that would have been transferred by mistake or acquired from
rebasing mechanisms. Internal function that can be exposed with access control if desired.*


```solidity
function recoverUnderlying() external onlyRole(RECOVERER_ROLE) returns (uint256);
```

### transferERC20

*Recover any ERC20 tokens that were accidentally sent to this contract.
Can only be called by admin. Cannot recover the underlying token - use claimAllRewards() for that.*


```solidity
function transferERC20(address tokenAddress, address tokenReceiver, uint256 tokenAmount)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The token contract address to recover|
|`tokenReceiver`|`address`|The address to send the tokens to|
|`tokenAmount`|`uint256`|The amount of tokens to recover|


### transferEth

*Recover ETH that was accidentally sent to this contract.
Can only be called by admin.*


```solidity
function transferEth(address payable _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address payable`|The address to send the ETH to|
|`_amount`|`uint256`||


### claimAllRewards

*Claim Aave rewards*


```solidity
function claimAllRewards(address rewardsController, address[] calldata assets, address to)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rewardsController`|`address`|Aave rewards controller contract|
|`assets`|`address[]`|tokens to claim|
|`to`|`address`|The address to send the rewards to|


## Errors
### ERC20InvalidUnderlying
*The underlying token couldn't be wrapped.*


```solidity
error ERC20InvalidUnderlying(address token);
```

