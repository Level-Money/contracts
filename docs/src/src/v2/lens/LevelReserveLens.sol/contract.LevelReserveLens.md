# LevelReserveLens
[Git Source](https://github.com/Level-Money/contracts/blob/8db01e6152f39f954577b5bcc8ca6a9c0b59a8cd/src/v2/lens/LevelReserveLens.sol)

**Inherits:**
Initializable, OwnableUpgradeable, UUPSUpgradeable, LevelReserveLensV1

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

**Note:**
changelog: Adds the balance of the BoringVault


## State Variables
### rewardsManager

```solidity
address public constant rewardsManager = 0x665DD2537426A92A3F89Da8E07f093919ecacF43;
```


## Functions
### _getReserves

Helper function to get the reserves of the given collateral token.


```solidity
function _getReserves(IERC20Metadata collateral, address waCollateralAddress, address symbioticVault)
    internal
    view
    override
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


