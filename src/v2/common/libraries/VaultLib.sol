// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.28;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {BoringVault} from "@level/src/v2/usd/BoringVault.sol";
import {StrategyLib, StrategyConfig, StrategyCategory} from "@level/src/v2/common/libraries/StrategyLib.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IPool} from "@level/src/v2/interfaces/aave/IPool.sol";
import {IPoolAddressesProvider} from "@level/src/v2/interfaces/aave/IPoolAddressesProvider.sol";
import {ISuperstateToken} from "@level/src/v2/interfaces/superstate/ISuperstateToken.sol";
import {IRedemption} from "@level/src/v2/interfaces/superstate/IRedemption.sol";
import {ISwapRouter} from "@level/src/v2/interfaces/uniswap/ISwapRouter.sol";
import {IERC4626StataToken} from "@level/src/v2/interfaces/aave/IERC4626StataToken.sol";
import {IERC4626StakeToken} from "@level/src/v2/interfaces/aave/IERC4626StakeToken.sol";

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

    /// @notice Emitted when assets are deposited into Spark
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountDeposited The amount of assets deposited
    /// @param sharesReceived The amount of shares received
    event DepositToSpark(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);

    /// @notice Emitted when assets are withdrawn from Spark
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountWithdrawn The amount of assets withdrawn
    /// @param sharesSent The amount of shares sent
    event WithdrawFromSpark(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);

    /// @notice Emitted when assets are withdrawn from Morpho
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountWithdrawn The amount of assets withdrawn
    /// @param sharesSent The amount of shares sent
    event WithdrawFromMorpho(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);

    /// @notice Emitted when assets are deposited into Superstate
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountDeposited The amount of assets deposited
    /// @param sharesReceived The amount of shares received
    event DepositToSuperstate(
        address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived
    );

    /// @notice Emitted when assets are withdrawn from Superstate
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountWithdrawn The amount of assets withdrawn
    /// @param sharesSent The amount of superstate token sent
    event WithdrawFromSuperstate(
        address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent
    );

    /// @notice Emitted when assets are deposited into M
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountDeposited The amount of assets deposited
    /// @param sharesReceived The amount of shares received
    event DepositToM0(address indexed vault, address indexed asset, uint256 amountDeposited, uint256 sharesReceived);

    /// @notice Emitted when assets are withdrawn from M
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountWithdrawn The amount of assets withdrawn
    /// @param sharesSent The amount of shares sent
    event WithdrawFromM0(address indexed vault, address indexed asset, uint256 amountWithdrawn, uint256 sharesSent);

    /// @notice Emitted when assets are staked to Aave Umbrella
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountStaked The amount of assets staked
    /// @param sharesReceived The amount of shares received
    event StakeToAaveUmbrella(
        address indexed vault, address indexed asset, uint256 amountStaked, uint256 sharesReceived
    );

    /// @notice Emitted when assets are unstaked from Aave Umbrella
    /// @param vault The vault address
    /// @param asset The asset address
    /// @param amountUnstaked The amount of assets unstaked
    /// @param sharesSent The amount of shares sent
    event UnstakeFromAaveUmbrella(
        address indexed vault, address indexed asset, uint256 amountUnstaked, uint256 sharesSent
    );

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
        uint256 i = 0;

        while (i < strategies.length && remainingAmount > 0) {
            StrategyConfig memory config = strategies[i];

            strategyBalance = StrategyLib.getAssets(config, address(vault));

            if (strategyBalance == 0) {
                i++;
                continue;
            }
            if (remainingAmount > strategyBalance) {
                withdrawn += _withdraw(vault, config, strategyBalance);
            } else {
                withdrawn += _withdraw(vault, config, remainingAmount);
            }

            if (withdrawn > amount) {
                remainingAmount = 0;
            } else {
                remainingAmount = amount - withdrawn;
            }

            i++;
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
        } else if (config.category == StrategyCategory.SPARK) {
            return _depositToSpark(vault, config, amount);
        } else if (config.category == StrategyCategory.SUPERSTATE) {
            return _depositToSuperstate(vault, config, amount);
        } else if (config.category == StrategyCategory.M0) {
            return _depositToM0(vault, config, amount);
        } else if (config.category == StrategyCategory.AAVEV3_UMBRELLA) {
            return _stakeToAaveUmbrella(vault, config, amount);
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
        } else if (config.category == StrategyCategory.SPARK) {
            return _withdrawFromSpark(vault, config, amount);
        } else if (config.category == StrategyCategory.SUPERSTATE) {
            return _withdrawFromSuperstate(vault, config, amount);
        } else if (config.category == StrategyCategory.M0) {
            return _withdrawFromM0(vault, config, amount);
        } else if (config.category == StrategyCategory.AAVEV3_UMBRELLA) {
            return _unstakeFromAaveUmbrella(vault, config, amount);
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

    /// @notice Deposits assets into Spark
    ///
    /// @dev In the future, Spark may charge fees on deposits.
    /// Depositing into spark inclues PSM fees for converting between USDC, DAI, and USDS
    /// These are all currently set to 0, but may change in the future.
    ///
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to deposit
    /// @return deposited The amount of assets deposited
    function _depositToSpark(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        vault.setTokenAllowance(address(_config.baseCollateral), _config.depositContract, amount);

        bytes memory sharesRaw = vault.manage(
            address(_config.depositContract),
            abi.encodeWithSignature("deposit(uint256,address,uint256,uint16)", amount, address(vault), 0, 181),
            0
        );

        uint256 shares_ = abi.decode(sharesRaw, (uint256));

        emit DepositToSpark(address(vault), address(_config.baseCollateral), amount, shares_);

        return amount;
    }

    /// @notice Withdraws assets from Spark
    ///
    /// @dev In the future, Spark may charge fees on withdrawals.
    /// Withdrawing from spark includes PSM fees for converting between USDC, DAI, and USDS
    /// These are all currently set to 0, but may change in the future.
    ///
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to withdraw
    /// @return withdrawn The amount of assets withdrawn
    function _withdrawFromSpark(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        IERC4626 sparkVault = IERC4626(_config.withdrawContract);

        uint256 sharesToRedeem = sparkVault.previewWithdraw(amount);

        if (sharesToRedeem == 0) {
            revert("VaultManager: amount must be greater than 0");
        }

        bytes memory sharesRaw = vault.manage(
            address(_config.withdrawContract),
            abi.encodeWithSignature("withdraw(uint256,address,address)", amount, address(vault), address(vault)),
            0
        );

        uint256 shares_ = abi.decode(sharesRaw, (uint256));

        emit WithdrawFromSpark(address(vault), address(_config.baseCollateral), amount, shares_);

        return amount;
    }

    /// @notice Deposits assets into Superstate
    ///
    /// @dev In the future, Superstate may charge fees on deposits.
    /// This will reduce the effective amount of base collateral received in USTB.
    /// This could temporarily reduce backing and lead to slight undercollateralization.
    /// However, such losses are expected to be recovered over time
    /// through the yield generated by the Superstate assets
    ///
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to deposit
    /// @return deposited The amount of assets deposited
    function _depositToSuperstate(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        vault.setTokenAllowance(address(_config.baseCollateral), _config.depositContract, amount);
        ISuperstateToken superstateToken = ISuperstateToken(_config.depositContract);
        (uint256 superstateTokenOutAmount, uint256 stablecoinInAmountAfterFee,) =
            superstateToken.calculateSuperstateTokenOut({inAmount: amount, stablecoin: address(_config.baseCollateral)});

        vault.manage(
            address(_config.depositContract),
            abi.encodeWithSignature("subscribe(uint256,address)", amount, address(_config.baseCollateral)),
            0
        );

        emit DepositToSuperstate(
            address(vault), address(_config.baseCollateral), stablecoinInAmountAfterFee, superstateTokenOutAmount
        );

        return stablecoinInAmountAfterFee;
    }

    /// @notice Withdraws assets from Superstate
    ///
    /// @dev In the future, Superstate may apply fees on redemptions, reducing the amount of collateral received.
    /// Any such loss should be offset by the yield earned while the assets were held in Superstate.
    ///
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to withdraw (USDC/USDT)
    /// @return withdrawn The amount of assets withdrawn
    function _withdrawFromSuperstate(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        IRedemption redemption = IRedemption(_config.withdrawContract);

        // Calculate the amount of superstate token to redeem
        (uint256 superstateTokenInAmount,) = redemption.calculateUstbIn(amount);

        // Approve the redemption contract to spend the superstate token
        vault.setTokenAllowance(address(_config.receiptToken), address(redemption), superstateTokenInAmount);

        vault.manage(address(redemption), abi.encodeWithSignature("redeem(uint256)", superstateTokenInAmount), 0);

        emit WithdrawFromSuperstate(address(vault), address(_config.baseCollateral), amount, superstateTokenInAmount);

        return amount;
    }

    /// @notice Deposits assets into M
    ///
    /// @dev The swap is subject to slippage, which may result in receiving fewer receipt tokens (e.g., wM)
    /// than the deposit amount. This slippage may lead to temporary undercollateralization.
    /// However, the loss is expected to be recovered over time through the yield generated by the wM position.
    ///
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to deposit
    /// @return deposited The amount of assets deposited
    function _depositToM0(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 deposited)
    {
        address baseCollateral = address(_config.baseCollateral);
        address wrappedM = address(_config.receiptToken);
        address swapManager = address(_config.depositContract);

        // Approve vault to move USDC → SwapManager
        vault.setTokenAllowance(baseCollateral, swapManager, amount);

        uint256 before = ERC20(wrappedM).balanceOf(address(vault));

        vault.manage(
            swapManager,
            abi.encodeWithSignature(
                "swap(address,address,uint256,address)", baseCollateral, wrappedM, amount, address(vault)
            ),
            0
        );

        uint256 afterBal = ERC20(wrappedM).balanceOf(address(vault));
        deposited = afterBal - before;

        emit DepositToM0(address(vault), baseCollateral, amount, deposited);

        return deposited;
    }

    /// @notice Withdraws assets from M
    ///
    /// @dev The withdrawal is subject to slippage, which may result in receiving slightly less base collateral
    /// than the wM amount. This may temporarily reduce collateral backing. However, the shortfall should be
    /// offset by the yield earned while holding the wM receipt tokens.
    ///
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to withdraw
    /// @return withdrawn The amount of assets withdrawn
    function _withdrawFromM0(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 withdrawn)
    {
        address baseCollateral = address(_config.baseCollateral);
        address wrappedM = address(_config.receiptToken);
        address swapManager = address(_config.depositContract);

        // Approve vault to move wM → SwapManager
        vault.setTokenAllowance(wrappedM, swapManager, amount);

        uint256 before = ERC20(baseCollateral).balanceOf(address(vault));

        vault.manage(
            swapManager,
            abi.encodeWithSignature(
                "swap(address,address,uint256,address)", wrappedM, baseCollateral, amount, address(vault)
            ),
            0
        );

        uint256 afterBal = ERC20(baseCollateral).balanceOf(address(vault));
        withdrawn = afterBal - before;

        emit WithdrawFromM0(address(vault), baseCollateral, withdrawn, amount);

        return withdrawn;
    }

    /// @notice Stakes wrapped aTokens into Aave Umbrella
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to stake
    /// @return staked The amount of assets staked
    function _stakeToAaveUmbrella(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 staked)
    {
        // config.baseCollateral is the USDC/USDT token
        // config.depositContract is the Aave Umbrella contract (stwaToken)
        // config.receiptToken is also stwaToken
        IERC4626StakeToken stakeToken = IERC4626StakeToken(_config.depositContract);
        IERC4626 stataToken = IERC4626(stakeToken.asset());

        // Convert Token to waToken
        vault.setTokenAllowance(address(_config.baseCollateral), address(stataToken), amount);
        bytes memory sharesRaw = vault.manage(
            address(stataToken), abi.encodeWithSignature("deposit(uint256,address)", amount, address(vault)), 0
        );

        uint256 waTokenBalance = abi.decode(sharesRaw, (uint256)); // waToken

        // Stake waTokens with Aave Umbrella
        vault.setTokenAllowance(address(stataToken), address(stakeToken), waTokenBalance);
        bytes memory stakedRaw = vault.manage(
            address(stakeToken), abi.encodeWithSignature("deposit(uint256,address)", waTokenBalance, address(vault)), 0
        );

        uint256 staked_ = abi.decode(stakedRaw, (uint256)); // st-waToken

        emit StakeToAaveUmbrella(address(vault), address(_config.baseCollateral), amount, staked_);

        return staked_;
    }

    /// @notice Unstakes waTokens from Aave Umbrella
    /// @param vault The vault address
    /// @param _config The strategy config
    /// @param amount The amount of assets to unstake (USDC/USDT)
    /// @return unstaked The amount of assets unstaked
    function _unstakeFromAaveUmbrella(BoringVault vault, StrategyConfig memory _config, uint256 amount)
        internal
        returns (uint256 unstaked)
    {
        // Get cooldown snapshot
        IERC4626StakeToken stakeToken = IERC4626StakeToken(_config.depositContract);
        IERC4626 stataToken = IERC4626(stakeToken.asset()); // waToken
        // cooldownSnapshot.amount is st-waToken
        IERC4626StakeToken.CooldownSnapshot memory cooldownSnapshot = stakeToken.getStakerCooldown(address(vault));

        if (
            block.timestamp >= cooldownSnapshot.endOfCooldown
                && block.timestamp - cooldownSnapshot.endOfCooldown <= cooldownSnapshot.withdrawalWindow
        ) {
            // How much waToken needs to be withdrawn to get the given amount of USDC/USDT
            uint256 waTokenAmount = stataToken.previewWithdraw(amount);

            // Check cooldown limits
            uint256 maxWithdrawal = stakeToken.maxWithdraw(address(vault));
            if (waTokenAmount > maxWithdrawal) {
                waTokenAmount = maxWithdrawal;
            }

            // We're in the withdrawal window
            bytes memory unstakedRaw = vault.manage(
                address(stakeToken),
                abi.encodeWithSignature(
                    "withdraw(uint256,address,address)", waTokenAmount, address(vault), address(vault)
                ),
                0
            );

            uint256 wrappedATokens = abi.decode(unstakedRaw, (uint256));

            bytes memory tokensRaw = vault.manage(
                address(stataToken),
                abi.encodeWithSignature(
                    "redeem(uint256,address,address)", wrappedATokens, address(vault), address(vault)
                ),
                0
            );

            uint256 tokens = abi.decode(tokensRaw, (uint256));

            emit UnstakeFromAaveUmbrella(address(vault), address(_config.baseCollateral), amount, tokens);

            return tokens;
        } else {
            // We're not in the withdrawal window, need to call cooldown
            revert("VaultManager: not in withdrawal window, call cooldown first");
        }
    }
}
