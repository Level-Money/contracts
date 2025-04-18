// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.28;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {StrategyLib, StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IPool} from "@level/src/v2/interfaces/aave/IPool.sol";
import {IPoolAddressesProvider} from "@level/src/v2/interfaces/aave/IPoolAddressesProvider.sol";
import {console2} from "forge-std/console2.sol";

library VaultLib {
    // Immutable Aave v3 pool addresses provider
    address public constant AAVE_V3_POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

    event DepositToAave(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);
    event WithdrawFromAave(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);
    event DepositToMorpho(
        address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived
    );
    event WithdrawFromMorpho(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);

    function _getTotalAssets(BoringVault vault, StrategyConfig[] memory strategies, address asset)
        internal
        view
        returns (uint256 total)
    {
        // Initialize to undeployed
        uint256 totalForAsset = ERC20(asset).balanceOf(address(vault));

        for (uint256 j = 0; j < strategies.length; j++) {
            StrategyConfig memory config = strategies[j];

            totalForAsset += StrategyLib.getAssets(config, address(vault));
        }

        return totalForAsset;
    }

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

    // Deposit asset into the vault. Shares should be minted 1:1 with the underlying, and shares should be stored in the vault.
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

    // Withdraw asset from the vault. Shares should be burned 1:1 with the underlying, and shares should be taken from the vault.
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

    /**
     * @dev aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.
     */
    function _depositToAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        address aaveV3 = _getAaveV3Pool();
        vault.increaseAllowance(address(_config.baseCollateral), aaveV3, amount);

        uint256 balanceBefore = ERC20(_config.baseCollateral).balanceOf(address(vault));
        vault.manage(
            address(aaveV3),
            abi.encodeWithSignature(
                "supply(address,uint256,address,uint16)", address(_config.baseCollateral), amount, address(vault), 0
            ),
            0
        );
        uint256 balanceAfter = ERC20(_config.baseCollateral).balanceOf(address(vault));

        uint256 deposited_ = balanceBefore - balanceAfter;
        emit DepositToAave(address(vault), address(_config.baseCollateral), amount, deposited_);

        return deposited_;
    }

    /**
     * @dev aTokens are not always 1:1 with the underlying asset; sometimes, it is off by one.
     */
    function _withdrawFromAave(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        address aaveV3 = _getAaveV3Pool();

        bytes memory withdrawnRaw = vault.manage(
            address(aaveV3),
            abi.encodeWithSignature(
                "withdraw(address,uint256,address)", address(_config.baseCollateral), amount, address(vault)
            ),
            0
        );

        uint256 withdrawn_ = abi.decode(withdrawnRaw, (uint256));

        emit WithdrawFromAave(address(vault), address(_config.baseCollateral), amount, withdrawn_);

        return withdrawn_;
    }

    function _getAaveV3Pool() internal view returns (address) {
        IPoolAddressesProvider provider = IPoolAddressesProvider(AAVE_V3_POOL_ADDRESSES_PROVIDER);
        return provider.getPool();
    }

    function _depositToMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        vault.increaseAllowance(address(_config.baseCollateral), _config.depositContract, amount);

        uint256 balanceBefore = ERC20(_config.baseCollateral).balanceOf(address(vault));

        bytes memory sharesRaw = vault.manage(
            address(_config.depositContract),
            abi.encodeWithSignature("deposit(uint256,address)", amount, address(vault)),
            0
        );
        uint256 balanceAfter = ERC20(_config.baseCollateral).balanceOf(address(vault));

        uint256 deposited_ = balanceBefore - balanceAfter;
        uint256 shares_ = abi.decode(sharesRaw, (uint256));

        emit DepositToMorpho(address(vault), address(_config.baseCollateral), deposited_, shares_);

        return deposited_;
    }

    function _withdrawFromMorpho(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        IERC4626 morphoVault = IERC4626(_config.withdrawContract);

        uint256 sharesToRedeem = morphoVault.previewWithdraw(amount);

        if (sharesToRedeem == 0) {
            revert("VaultManager: amount must be greater than 0");
        }

        uint256 balanceBefore = _config.baseCollateral.balanceOf(address(vault));
        bytes memory sharesRaw = vault.manage(
            address(_config.withdrawContract),
            abi.encodeWithSignature("withdraw(uint256,address,address)", amount, address(vault), address(vault)),
            0
        );
        uint256 balanceAfter = _config.baseCollateral.balanceOf(address(vault));

        uint256 withdrawn_ = balanceAfter - balanceBefore;
        uint256 shares_ = abi.decode(sharesRaw, (uint256));

        emit WithdrawFromMorpho(address(vault), address(_config.baseCollateral), withdrawn_, shares_);

        return withdrawn_;
    }
}
