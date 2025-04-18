# LevelMintingV2
[Git Source](https://github.com/Level-Money/contracts/blob/dc473999128bb60d87e479b557f6971af65ff8db/src/v2/LevelMintingV2.sol)

**Inherits:**
[LevelMintingV2Storage](/src/v2/LevelMintingV2Storage.sol/abstract.LevelMintingV2Storage.md), Initializable, UUPSUpgradeable, [AuthUpgradeable](/src/v2/auth/AuthUpgradeable.sol/abstract.AuthUpgradeable.md), [PauserGuarded](/src/v2/common/guard/PauserGuarded.sol/abstract.PauserGuarded.md)


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(
    address _admin,
    uint256 _maxMintPerBlock,
    uint256 _maxRedeemPerBlock,
    address _authority,
    address _vaultManager,
    address _guard
) external initializer;
```

### mint


```solidity
function mint(Order calldata order) external requiresAuth notPaused returns (uint256 lvlUsdMinted);
```

### initiateRedeem


```solidity
function initiateRedeem(address asset, uint256 lvlUsdAmount, uint256 expectedAmount)
    external
    requiresAuth
    notPaused
    returns (uint256, uint256);
```

### completeRedeem


```solidity
function completeRedeem(address asset, address beneficiary) external notPaused returns (uint256 collateralAmount);
```

### setGuard


```solidity
function setGuard(address _guard) external requiresAuth;
```

### verifyOrder

assert validity of order


```solidity
function verifyOrder(Order memory order) public view;
```

### computeMint

This function could take in either a base collateral (ie USDC/USDT) or a receipt token (ie Morpho vault share, aUSDC/T)
If we receive a receipt token, we need to first convert the receipt token to the amount of underlying it can be redeemd for
before applying the underlying's USD price and calculating the lvlUSD amount to mint


```solidity
function computeMint(address collateralAsset, uint256 collateralAmount) public view returns (uint256 lvlusdAmount);
```

### computeRedeem


```solidity
function computeRedeem(address asset, uint256 lvlusdAmount) public view returns (uint256 collateralAmount);
```

### getPriceAndDecimals


```solidity
function getPriceAndDecimals(address collateralToken) public view returns (int256 price, uint256 decimal);
```

### setMaxMintPerBlock

Sets the max mintPerBlock limit
Callable by ADMIN_ROLE


```solidity
function setMaxMintPerBlock(uint256 _maxMintPerBlock) external requiresAuth;
```

### setMaxRedeemPerBlock

Sets the max redeemPerBlock limit
Callable by ADMIN_ROLE


```solidity
function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external requiresAuth;
```

### disableMintRedeem

Disables the mint and redeem
Callable by GATEKEEPER_ROLE and ADMIN_ROLE


```solidity
function disableMintRedeem() external requiresAuth;
```

### setBaseCollateral


```solidity
function setBaseCollateral(address asset, bool isBase) external requiresAuth;
```

### addMintableAsset

Adds an asset to the supported assets list.
Callable by ADMIN_ROLE (admin timelock)


```solidity
function addMintableAsset(address asset) public requiresAuth;
```

### addRedeemableAsset

Adds an asset to the redeemable assets list.
Callable by ADMIN_ROLE (admin timelock)


```solidity
function addRedeemableAsset(address asset) public requiresAuth;
```

### removeMintableAsset

Removes an asset from the supported assets list


```solidity
function removeMintableAsset(address asset) external requiresAuth;
```

### removeRedeemableAsset

Removes an asset from the redeemable assets list


```solidity
function removeRedeemableAsset(address asset) external requiresAuth;
```

### addOracle


```solidity
function addOracle(address collateral, address oracle, bool _isLevelOracle) public requiresAuth;
```

### removeOracle

Callable by ADMIN_ROLE (admin timelock)


```solidity
function removeOracle(address collateral) public requiresAuth;
```

### setHeartBeat


```solidity
function setHeartBeat(address collateral, uint256 heartBeat) public requiresAuth;
```

### setCooldownDuration


```solidity
function setCooldownDuration(uint256 newduration) external requiresAuth;
```

### setVaultManager


```solidity
function setVaultManager(address _vaultManager) external requiresAuth;
```

### _setMaxMintPerBlock

Sets the max mintPerBlock limit


```solidity
function _setMaxMintPerBlock(uint256 _maxMintPerBlock) internal;
```

### _setMaxRedeemPerBlock

Sets the max redeemPerBlock limit


```solidity
function _setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) internal;
```

### _authorizeUpgrade

*Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeToAndCall}.
Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
```solidity
function _authorizeUpgrade(address) internal onlyOwner {}
```*


```solidity
function _authorizeUpgrade(address newImplementation) internal override requiresAuth;
```

