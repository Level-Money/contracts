# AuthUpgradeable
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v2/auth/AuthUpgradeable.sol)

**Inherits:**
Initializable

**Authors:**
Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol), Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol), Modified for upgradeability

.-==+=======+:
:---=-::-==:
.-:-==-:-==:
.:::--::::::.     .--:-=--:--.       .:--:::--..
.=++=++:::::..     .:::---::--.    ....::...:::.
:::-::..::..      .::::-:::::.     ...::...:::.
...::..::::..     .::::--::-:.    ....::...:::..
............      ....:::..::.    ------:......
...........     ........:....     .....::..:..    ======-......      ...........
:------:.:...   ...:+***++*#+     .------:---.    ...::::.:::...   .....:-----::.
.::::::::-:..   .::--..:-::..    .-=+===++=-==:   ...:::..:--:..   .:==+=++++++*:

Provides a flexible and updatable auth pattern which is completely separate from application logic.


## State Variables
### owner

```solidity
address public owner;
```


### authority

```solidity
Authority public authority;
```


### __gap
*This empty reserved space is put in place to allow future versions to add new
variables without shifting down storage in the inheritance chain.
See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps*


```solidity
uint256[50] private __gap;
```


## Functions
### __Auth_init


```solidity
function __Auth_init(address _owner, address _authority) internal onlyInitializing;
```

### requiresAuth


```solidity
modifier requiresAuth() virtual;
```

### isAuthorized


```solidity
function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool);
```

### setAuthority


```solidity
function setAuthority(Authority newAuthority) public virtual;
```

### transferOwnership


```solidity
function transferOwnership(address newOwner) public virtual requiresAuth;
```

## Events
### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed user, address indexed newOwner);
```

### AuthorityUpdated

```solidity
event AuthorityUpdated(address indexed user, Authority indexed newAuthority);
```

