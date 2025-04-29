# LevelReserveLens
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v1/lens/LevelReserveLens.sol)

**Inherits:**
[ILevelReserveLens](/src/v1/interfaces/lens/ILevelReserveLens.sol/interface.ILevelReserveLens.md), Initializable, OwnableUpgradeable, UUPSUpgradeable

**Author:**
Level (https://level.money)

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

The LevelReserveLens contract is a simple contract that allows users to query the reserves backing lvlUSD per underlying collateral token address.

*It is upgradeable so that we can add future reserve managers without affecting downstream consumers.*


## State Variables
### levelMintingAddress

```solidity
address public constant levelMintingAddress = 0x8E7046e27D14d09bdacDE9260ff7c8c2be68a41f;
```


### eigenReserveManager

```solidity
address public constant eigenReserveManager = 0x7B2c2C905184CEf1FABe920D4CbEA525acAa6f14;
```


### symbioticReserveManager

```solidity
address public constant symbioticReserveManager = 0x21C937d436f2D86859ce60311290a8072368932D;
```


### karakReserveManager

```solidity
address public constant karakReserveManager = 0x329F91FE82c1799C3e089FabE9D3A7efDC2D3151;
```


### waUsdcSymbioticVault

```solidity
address public constant waUsdcSymbioticVault = 0x67F91a36c5287709E68E3420cd17dd5B13c60D6d;
```


### waUsdtSymbioticVault

```solidity
address public constant waUsdtSymbioticVault = 0x9BF93077Ad7BB7f43E177b6AbBf8Dae914761599;
```


### usdcAddress

```solidity
address public constant usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
```


### usdtAddress

```solidity
address public constant usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
```


### waUsdcAddress

```solidity
address public constant waUsdcAddress = 0x78c6B27Be6DB520d332b1b44323F94bC831F5e33;
```


### waUsdtAddress

```solidity
address public constant waUsdtAddress = 0xb723377679b807370Ae8615ae3E76F6D1E75a5F2;
```


### lvlusdAddress

```solidity
address public constant lvlusdAddress = 0x7C1156E515aA1A2E851674120074968C905aAF37;
```


### usdcOracle

```solidity
address public constant usdcOracle = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
```


### usdtOracle

```solidity
address public constant usdtOracle = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
```


### LVLUSD_DECIMALS

```solidity
uint8 public constant LVLUSD_DECIMALS = 18;
```


## Functions
### constructor

**Note:**
oz-upgrades-unsafe-allow: constructor


```solidity
constructor();
```

### initialize

*Initializes the contract setting the deployer as the initial owner.*


```solidity
function initialize(address admin) public initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin`|`address`|The address of the admin of the contract.|


### getReserves

Returns the reserves of the given token, including any lending derivatives. For example, if the token is USDC, we will return the balance of all ReserveManagers' USDC and wrapped Aave tokens. Also includes reserves in LevelMinting.

*Note: waUSDC/T and USDC/T are used interchangeably because the wrapped Aave tokens are withdrawable 1:1 for the underlying token*


```solidity
function getReserves(address collateral) public view virtual override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The reserves of the given token, in lvlUSD's decimals (18)|


### getReserveValue

Returns the USD-value reserves of the given token. See getReserves for more details.


```solidity
function getReserveValue(address collateral) public view override returns (uint256 usdReserves);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`address`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`usdReserves`|`uint256`|The USD-value reserves of the given token, in lvlUSD's decimals (18)|


### getReserveValue

Returns the USD-value reserves of the given token. See getReserves for more details.


```solidity
function getReserveValue() public view override returns (uint256 usdReserves);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`usdReserves`|`uint256`|The USD-value reserves of the given token, in lvlUSD's decimals (18)|


### getReservePrice

Returns the reserve price of lvlUSD. If the reserves are overcollateralized, return $1 (1e18). Otherwise, return the ratio of USD reserves to lvlUSD supply.


```solidity
function getReservePrice() public view override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|reservePrice The reserve price of lvlUSD, with lvlUSD's decimals (18).|


### getReservePriceDecimals

Returns the number of decimals used for the reserve price.


```solidity
function getReservePriceDecimals() external pure override returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|reservePriceDecimals The number of decimals used for the reserve price|


### getMintPrice

Returns the price of minting lvlUSD using the same logic as LevelMinting


```solidity
function getMintPrice(IERC20Metadata collateral) external view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|mintPrice The price of lvlUSD for 1 unit of the collateral token, with lvlUSD's decimals (18)|


### getRedeemPrice

Returns the price of redeeming lvlUSD using the same logic as LevelMinting


```solidity
function getRedeemPrice(IERC20Metadata collateral) external view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|redeemPrice The price of collateral for 1 unit of lvlUSD, with the same decimals as the collateral token|


### getSymbioticStake

Returns the underlying tokens staked in a given Symbiotic vault and burner

*Note: as of this implementation, Level is not depositing into EigenLayer. We intend to add accounting for collateral deposited into EigenLayer before we deposit.*


```solidity
function getSymbioticStake(IERC20Metadata collateral, address vault) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token|
|`vault`|`address`|The address of the Symbiotic vault|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|symbioticStake The total collateral tokens held by the given vault and vault burner|


### safeAdjustForDecimals

Adjusts the amount for the difference in decimals. Reverts with underflow if fromDecimals is greater than toDecimals (ie the amount would lose precision).


```solidity
function safeAdjustForDecimals(uint256 amount, uint8 fromDecimals, uint8 toDecimals) public pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to adjust|
|`fromDecimals`|`uint8`|The decimals of the amount|
|`toDecimals`|`uint8`|The decimals to adjust to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|adjustedAmount The adjusted amount|


### _getReserves

Helper function to get the reserves of the given collateral token.


```solidity
function _getReserves(IERC20Metadata collateral, address waCollateralAddress, address symbioticVault)
    internal
    view
    virtual
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`IERC20Metadata`|The address of the collateral token.|
|`waCollateralAddress`|`address`|The address of the wrapped Aave token for the collateral.|
|`symbioticVault`|`address`|The address of the Symbiotic vault for the collateral.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|reserves The lvlUSD reserves for a given collateral token, in the given token's decimals.|


### _authorizeUpgrade

*Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeToAndCall}.
Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
```solidity
function _authorizeUpgrade(address) internal onlyOwner {}
```*


```solidity
function _authorizeUpgrade(address) internal override onlyOwner;
```

