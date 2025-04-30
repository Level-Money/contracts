// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.28;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {StrategyLib, StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IPool} from "@level/src/v2/interfaces/aave/IPool.sol";
import {IPoolAddressesProvider} from "@level/src/v2/interfaces/aave/IPoolAddressesProvider.sol";

/// @title VaultLib
/// @author Level (https://level.money)
/// @notice Library to manage vault operations, such as depositing into and withdrawing from strategies
library VaultLib {
    // Immutable Aave v3 pool addresses provider
    address public constant AAVE_V3_POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

    /// @notice Emitted when assets are deposited into Aave v3
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountDeposited The amount of assets deposited
    /// @param sharesReceived The amount of shares received
    event DepositToAave(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);

    /// @notice Emitted when assets are withdrawn from Aave v3
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountWithdrawn The amount of assets withdrawn
    /// @param sharesSent The amount of shares sent
    event WithdrawFromAave(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);

    /// @notice Emitted when assets are deposited into Morpho
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountDeposited The amount of assets deposited
    /// @param sharesReceived The amount of shares received
    event DepositToMorpho(
        address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived
    );

    /// @notice Emitted when assets are withdrawn from Morpho
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountWithdrawn The amount of assets withdrawn
    /// @param sharesSent The amount of shares sent
    event WithdrawFromMorpho(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);

    /// @notice Returns the total assets of the given strategies
    /// @param vault The vault address
    /// @param strategies The strategy configs
    /// @param asset The asset address
    /// @return total The total assets of the given strategies, denominated in the common base collateral
    function _getTotalAssets(BoringVault vault, StrategyConfig[] memory strategies, address asset)
        internal
        view
        returns (uint256 total)
    {
        // Initialize to undeployed
        uint256 totalForAsset = ERC20(asset).balanceOf(address(vault));

        totalForAsset += StrategyLib.getAssets(strategies, address(vault));

        return totalForAsset;
    }

    /// @notice Withdraws assets from the given strategies
    /// @dev Assumes that all strategies share the same `baseCollateral`
    /// @param vault The vault address
    /// @param strategies The strategy configs
    /// @param amount The amount of assets to withdraw
    /// @return withdrawn The amount of assets withdrawn, using the common baseCollateral's decimals
    function _withdrawBatch(BoringVault vault, StrategyConfig[] memory strategies, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        uint256 strategyBalance;
        uint256 remainingAmount = amount;
        withdrawn = 0;

        for (uint256 i; i < strategies.length; i++) {
            StrategyConfig memory config = strategies[i];

            strategyBalance = StrategyLib.getAssets(config, address(vault));

            if (strategyBalance == 0) {
                continue;
            }
            if (remainingAmount > strategyBalance) {
                withdrawn += _withdraw(vault, config, strategyBalance);
                remainingAmount -= strategyBalance;
            } else {
                withdrawn += _withdraw(vault, config, remainingAmount);

                break;
            }
        }

        return withdrawn;
    }

    /// @notice Deposits assets into the given strategy
    /// @param vault The vault address
    /// @param config The strategy config
    /// @param amount The amount of assets to deposit
    /// @return deposited The amount of assets deposited
    function _deposit(BoringVault vault, StrategyConfig memory config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        if (config.category == StrategyCategory.AAVEV3) {
            return _depositToAave(vault, config, amount);
        } else if (config.category == StrategyCategory.MORPHO) {
            return _depositToMorpho(vault, config, amount);
        } else {
            revert("VaultManager: unsupported strategy");
        }
    }

    /// @notice Withdraws assets from the given strategy
    /// @param vault The vault address
    /// @param config The strategy config
    /// @param amount The amount of assets to withdraw
    /// @return withdrawn The amount of assets withdrawn
    function _withdraw(BoringVault vault, StrategyConfig memory config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        if (config.category == StrategyCategory.AAVEV3) {
            return _withdrawFromAave(vault, config, amount);
        } else if (config.category == StrategyCategory.MORPHO) {
            return _withdrawFromMorpho(vault, config, amount);
        } else {
            revert("VaultManager: unsupported strategy");
        }
    }

    /// @notice Deposits assets into Aave v3
    /// @dev aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to deposit
    /// @return deposited The amount of assets deposited
    function _depositToAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        address aaveV3 = _getAaveV3Pool();
        vault.setTokenAllowance(address(_config.baseCollateral), aaveV3, amount);

        uint256 sharesBefore = ERC20(_config.receiptToken).balanceOf(address(vault));
        vault.manage(
            address(aaveV3),
            abi.encodeWithSignature(
                "supply(address,uint256,address,uint16)", address(_config.baseCollateral), amount, address(vault), 0
            ),
            0
        );
        uint256 sharesAfter = ERC20(_config.receiptToken).balanceOf(address(vault));

        uint256 shares = sharesAfter - sharesBefore;
        emit DepositToAave(address(vault), address(_config.baseCollateral), amount, shares);

        return amount;
    }

    /// @notice Withdraws assets from Aave v3
    /// @dev aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to withdraw
    /// @return withdrawn The amount of assets withdrawn
    function _withdrawFromAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        address aaveV3 = _getAaveV3Pool();

        uint256 sharesBefore = ERC20(_config.receiptToken).balanceOf(address(vault));
        bytes memory withdrawnRaw = vault.manage(
            address(aaveV3),
            abi.encodeWithSignature(
                "withdraw(address,uint256,address)", address(_config.baseCollateral), amount, address(vault)
            ),
            0
        );

        uint256 sharesAfter = ERC20(_config.receiptToken).balanceOf(address(vault));
        uint256 shares = sharesBefore - sharesAfter;

        uint256 withdrawn_ = abi.decode(withdrawnRaw, (uint256));

        emit WithdrawFromAave(address(vault), address(_config.baseCollateral), withdrawn_, shares);

        return withdrawn_;
    }

    /// @notice Returns the Aave v3 pool address
    /// @return pool_ The Aave v3 pool address
    function _getAaveV3Pool() internal view returns (address) {
        IPoolAddressesProvider provider = IPoolAddressesProvider(AAVE_V3_POOL_ADDRESSES_PROVIDER);
        return provider.getPool();
    }

    /// @notice Deposits assets into Morpho
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to deposit
    /// @return deposited The amount of assets deposited
    function _depositToMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        vault.setTokenAllowance(address(_config.baseCollateral), _config.depositContract, amount);

        bytes memory sharesRaw = vault.manage(
            address(_config.depositContract),
            abi.encodeWithSignature("deposit(uint256,address)", amount, address(vault)),
            0
        );

        uint256 shares_ = abi.decode(sharesRaw, (uint256));

        emit DepositToMorpho(address(vault), address(_config.baseCollateral), amount, shares_);

        return amount;
    }

    /// @notice Withdraws assets from Morpho
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to withdraw
    /// @return withdrawn The amount of assets withdrawn
    function _withdrawFromMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        IERC4626 morphoVault = IERC4626(_config.withdrawContract);

        uint256 sharesToRedeem = morphoVault.previewWithdraw(amount);

        if (sharesToRedeem == 0) {
            revert("VaultManager: amount must be greater than 0");
        }

        bytes memory sharesRaw = vault.manage(
            address(_config.withdrawContract),
            abi.encodeWithSignature("withdraw(uint256,address,address)", amount, address(vault), address(vault)),
            0
        );

        uint256 shares_ = abi.decode(sharesRaw, (uint256));

        emit WithdrawFromMorpho(address(vault), address(_config.baseCollateral), amount, shares_);

        return amount;
    }
}
