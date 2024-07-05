// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IlvlUSD.sol";
import "./SingleAdminAccessControl.sol";
import "./Freezer.sol";

contract Slasher is SingleAdminAccessControl {
    IlvlUSD immutable LVLUSD;

    /// @notice list of addresses that have transferred funds to this contract, and to which funds can be withdrawn
    mapping(address => bool) private freezers;

    event WithdrawnFromFreezerToSlasher(
        address freezer,
        address slasher,
        uint256 amount
    );
    event SlashingEvent(address slasher, uint256 amount);
    event FreezerAdded(address freezer);
    event FreezerRemoved(address freezer);

    /// @notice Zero address not allowed
    error ZeroAddressException();
    error NonFreezerReceiver();
    error InvalidFreezer();
    error FreezerAlreadyAdded();
    error NotAFreezer();

    constructor(
        address admin,
        address asset // lvlUSD
    ) {
        if (admin == address(0)) revert ZeroAddressException();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        LVLUSD = IlvlUSD(asset);
    }

    function addFreezer(address freezer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (freezers[freezer]) {
            revert FreezerAlreadyAdded();
        }
        freezers[freezer] = true;
        emit FreezerAdded(freezer);
    }

    function removeFreezer(
        address freezer
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!freezers[freezer]) {
            revert NotAFreezer();
        }
        freezers[freezer] = false;
        emit FreezerRemoved(freezer);
    }

    /**
     * @notice Allows someone with DEFAULT_ADMIN_ROLE to withdraw funds from freezer to this contract
     * @param amount amount of LVLUSD to withdraw
     */
    function withdrawFromFreezer(
        address freezer,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!freezers[freezer]) revert InvalidFreezer();
        Freezer(freezer).withdraw(amount);
        emit WithdrawnFromFreezerToSlasher(freezer, address(this), amount);
    }

    /**
     * @notice Allows the owner (DEFAULT_ADMIN_ROLE) to withdraw funds to a receiver address.
     * @param amount amount of LVLUSD to withdraw
     */
    function withdraw(
        address receiver,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!freezers[receiver]) revert NonFreezerReceiver();
        LVLUSD.transfer(receiver, amount);
    }

    /**
     * @notice Allows the owner (DEFAULT_ADMIN_ROLE) to burn (slash) lvlUSD
     * @param amount amount of LVLUSD to burn
     */
    function burn(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        LVLUSD.burn(amount);
        emit SlashingEvent(address(this), amount);
    }
}
