// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {Auth, Authority} from "@solmate/src/auth/Auth.sol";
import {PauserGuarded} from "@level/src/v2/common/guard/PauserGuarded.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface BeforeTransferHook {
    function beforeTransfer(address from, address to, address operator) external view;
}

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
 * @title BoringVault
 * @author Level (https://level.money)
 * @notice The BoringVault contract is a simple contract that allows users to deposit and withdraw assets.
 * @notice Forked from Veda's BoringVault standard. Adds PauserGuarded, method to recover ETH, and `setTokenAllowance`
 */
contract BoringVault is ERC20, Auth, ERC721Holder, ERC1155Holder, PauserGuarded {
    using Address for address;
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // ========================================= STATE =========================================

    /**
     * @notice Contract responsbile for implementing `beforeTransfer`.
     */
    BeforeTransferHook public hook;

    //============================== EVENTS ===============================

    event Enter(address indexed from, address indexed asset, uint256 amount, address indexed to, uint256 shares);
    event Exit(address indexed to, address indexed asset, uint256 amount, address indexed from, uint256 shares);
    event EthRecovered(address indexed to, uint256 amount);

    //============================== CONSTRUCTOR ===============================

    constructor(address _owner, string memory _name, string memory _symbol, uint8 _decimals, address _guard)
        ERC20(_name, _symbol, _decimals)
        Auth(_owner, Authority(address(0)))
        PauserGuarded(_guard)
    {}

    //============================== MANAGE ===============================

    /**
     * @notice Allows manager to make an arbitrary function call from this contract.
     * @dev Callable by MANAGER_ROLE.
     */
    function manage(address target, bytes calldata data, uint256 value)
        external
        notPaused
        requiresAuth
        returns (bytes memory result)
    {
        result = target.functionCallWithValue(data, value);
    }

    /**
     * @notice Allows manager to make arbitrary function calls from this contract.
     * @dev Callable by MANAGER_ROLE.
     */
    function manage(address[] calldata targets, bytes[] calldata data, uint256[] calldata values)
        external
        notPaused
        requiresAuth
        returns (bytes[] memory results)
    {
        uint256 targetsLength = targets.length;
        results = new bytes[](targetsLength);
        for (uint256 i; i < targetsLength; ++i) {
            results[i] = targets[i].functionCallWithValue(data[i], values[i]);
        }
    }

    //============================== ENTER ===============================

    /**
     * @notice Allows minter to mint shares, in exchange for assets.
     * @dev If assetAmount is zero, no assets are transferred in.
     * @dev Callable by MINTER_ROLE.
     */
    function enter(address from, ERC20 asset, uint256 assetAmount, address to, uint256 shareAmount)
        external
        notPaused
        requiresAuth
    {
        // Transfer assets in
        if (assetAmount > 0) asset.safeTransferFrom(from, address(this), assetAmount);

        // Mint shares.
        _mint(to, shareAmount);

        emit Enter(from, address(asset), assetAmount, to, shareAmount);
    }

    //============================== EXIT ===============================

    /**
     * @notice Allows burner to burn shares, in exchange for assets.
     * @dev If assetAmount is zero, no assets are transferred out.
     * @dev Callable by BURNER_ROLE.
     */
    function exit(address to, ERC20 asset, uint256 assetAmount, address from, uint256 shareAmount)
        external
        notPaused
        requiresAuth
    {
        // Burn shares.
        _burn(from, shareAmount);

        // Transfer assets out.
        if (assetAmount > 0) asset.safeTransfer(to, assetAmount);

        emit Exit(to, address(asset), assetAmount, from, shareAmount);
    }

    //============================== BEFORE TRANSFER HOOK ===============================
    /**
     * @notice Sets the share locker.
     * @notice If set to zero address, the share locker logic is disabled.
     * @dev Callable by OWNER_ROLE.
     */
    function setBeforeTransferHook(address _hook) external notPaused requiresAuth {
        hook = BeforeTransferHook(_hook);
    }

    /**
     * @notice Call `beforeTransferHook` passing in `from` `to`, and `msg.sender`.
     */
    function _callBeforeTransfer(address from, address to) internal view {
        if (address(hook) != address(0)) hook.beforeTransfer(from, to, msg.sender);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _callBeforeTransfer(msg.sender, to);
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _callBeforeTransfer(from, to);
        return super.transferFrom(from, to, amount);
    }

    //============================== APPROVAL ===============================

    function setTokenAllowance(address token, address spender, uint256 amount) external notPaused requiresAuth {
        SafeERC20.forceApprove(IERC20(token), spender, amount);
    }

    //============================== OWNER ===============================

    function recoverEth(uint256 amount) external requiresAuth {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        SafeTransferLib.safeTransferETH(msg.sender, amount);
        emit EthRecovered(msg.sender, amount);
    }

    //============================== PAUSER ===============================

    function setGuard(address _guard) external requiresAuth {
        _setGuard(_guard);
    }

    //============================== RECEIVE ===============================

    receive() external payable {}
}
