// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC4626Oracle} from "@level/src/v2/interfaces/level/IERC4626Oracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 *                                     .-==+=======+:
 *                                      :---=-::-==:
 *                                      .-:-==-:-==:
 *                    .:::--::::::.     .--:-=--:--.       .:--:::--..
 *                   .=++=++:::::..     .:::---::--.    ....::...:::.
 *                    :::-::..::..      .::::-:::::.     ...::...:::.
 *                    ...::..::::..     .::::--::-:.    ....::...:::..
 *                    ............      ....:::..::.    ------:......
 *    ...........     ........:....     .....::..:..    ======-......      ...........
 *    :------:.:...   ...:+***++*#+     .------:---.    ...::::.:::...   .....:-----::.
 *    .::::::::-:..   .::--..:-::..    .-=+===++=-==:   ...:::..:--:..   .:==+=++++++*:
 *
 * @title AaveUmbrellaOracle
 * @author Level (https://level.money)
 * @notice Oracle contract for Aave Umbrella aToken vaults.
 * @notice Returns the price of a staked-wrapped-aToken in terms of the underlying token
 */
contract AaveUmbrellaOracle is IERC4626Oracle {
    IERC4626 public immutable stakedWrappedVault;

    uint8 public immutable decimals_;
    uint256 public immutable oneShare;

    constructor(IERC4626 _stakedWrappedVault) {
        stakedWrappedVault = _stakedWrappedVault;
        IERC4626 wrappedAaveToken = IERC4626(stakedWrappedVault.asset()); // waToken

        decimals_ = IERC20Metadata(wrappedAaveToken.asset()).decimals(); // decimals of underlying Token
        oneShare = 10 ** stakedWrappedVault.decimals();
    }

    function update() external {}

    function decimals() external view returns (uint8) {
        return decimals_;
    }

    function description() external pure returns (string memory) {
        return "Chainlink-compliant Aave Umbrella Oracle";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 /*_roundId */ ) external view returns (uint80, int256, uint256, uint256, uint80) {
        return this.latestRoundData();
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        uint256 amountOfWrappedATokens = stakedWrappedVault.convertToAssets(oneShare); // 1 st-waToken to waToken
        uint256 amountOfUnderlyingTokens = IERC4626(stakedWrappedVault.asset()).convertToAssets(amountOfWrappedATokens); // waToken to underlying Token
        return (0, int256(amountOfUnderlyingTokens), block.timestamp, block.timestamp, 0);
    }
}
