// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import {SingleAdminAccessControl} from "../SingleAdminAccessControl.sol";
import {BaseYieldManager} from "./BaseYieldManager.sol";
import "../WrappedRebasingERC20.sol";
import {ERC20} from "@openzeppelin-4.9.0/contracts/token/ERC20/ERC20.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {DataTypes} from "aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";

/**
 * @title Aave Yield Manager
 * @notice This contract serves as middleware to wrap native tokens into ERC20
 *          wrapped aTokens
 */
contract AaveV3YieldManager is BaseYieldManager {
    using SafeERC20 for IERC20;

    event DepositedToAave(uint amount, address token);
    event WithdrawnFromAave(uint amount, address token);

    error TokenERC20WrapperNotSet();
    error InvalidWrapper();
    error TokenAndWrapperDecimalsMismatch();

    /* --------------- STATE VARIABLES --------------- */

    // aave pool proxy
    IPool public aavePoolProxy;
    mapping(address => address) public aTokenToUnderlying;
    mapping(address => address) public underlyingToaToken;

    // mapping of a token address to an ERC20 wrapper address
    mapping(address => address) public tokenToWrapper;

    /* --------------- CONSTRUCTOR --------------- */

    constructor(IPool _aavePoolProxy, address _admin) BaseYieldManager(_admin) {
        aavePoolProxy = _aavePoolProxy;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /* --------------- INTERNAL --------------- */

    function _wrapToken(address token, uint256 amount) internal {
        if (tokenToWrapper[token] == address(0)) {
            revert TokenERC20WrapperNotSet();
        }
        ERC20Wrapper(tokenToWrapper[token]).depositFor(address(this), amount);
    }

    function _unwrapToken(address wrapper, uint256 amount) internal {
        ERC20Wrapper(wrapper).withdrawTo(address(this), amount);
    }

    function _withdrawFromAave(address token, uint256 amount) internal {
        aavePoolProxy.withdraw(token, amount, address(this));
        emit WithdrawnFromAave(amount, token);
    }

    function _depositToAave(address token, uint256 amount) internal {
        aavePoolProxy.supply(token, amount, address(this), 0);
        emit DepositedToAave(amount, token);
    }

    function _getATokenAddress(address underlying) internal returns (address) {
        DataTypes.ReserveData memory reserveData = aavePoolProxy.getReserveData(
            underlying
        );
        if (aTokenToUnderlying[reserveData.aTokenAddress] == address(0)) {
            aTokenToUnderlying[reserveData.aTokenAddress] = underlying;
        }
        if (underlyingToaToken[underlying] == address(0)) {
            underlyingToaToken[underlying] = reserveData.aTokenAddress;
        }
        return reserveData.aTokenAddress;
    }

    /* --------------- EXTERNAL --------------- */

    // deposit collateral to Aave pool, and immediately wrap AToken in
    // wrapper class, so that AToken rewards accrue to that contract and not this one.
    // https://docs.aave.com/developers/deployed-contracts/v3-testnet-addresses
    function depositForYield(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _depositToAave(token, amount);
        address aTokenAddress = _getATokenAddress(token);
        _wrapToken(aTokenAddress, amount);
        IERC20(tokenToWrapper[aTokenAddress]).transfer(msg.sender, amount);
    }

    function withdraw(
        address token, // e.g. USDC
        uint256 amount
    ) external {
        address aTokenAddress = underlyingToaToken[token];
        address wrapper = tokenToWrapper[aTokenAddress];
        IERC20(wrapper).safeTransferFrom(msg.sender, address(this), amount);
        _unwrapToken(wrapper, amount);
        _withdrawFromAave(token, amount);
        IERC20(token).transfer(msg.sender, amount);
    }

    /* --------------- SETTERS --------------- */

    function setAaveV3PoolAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aavePoolProxy = IPool(newAddress);
    }

    function setWrapperForToken(
        address token,
        address wrapper
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(ERC20Wrapper(wrapper).underlying()) != token) {
            revert InvalidWrapper();
        }
        if (ERC20(token).decimals() != ERC20(wrapper).decimals()) {
            revert TokenAndWrapperDecimalsMismatch();
        }
        tokenToWrapper[token] = wrapper;
    }
}
