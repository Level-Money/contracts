// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract MockVaultManager {
    bool public shouldDepositDefaultRevert;
    bool public shouldWithdrawDefaultRevert;

    address public vault;

    constructor(address _vault) {
        vault = _vault;
    }

    function setShouldDepositDefaultRevert(bool _shouldDepositDefaultRevert) public {
        shouldDepositDefaultRevert = _shouldDepositDefaultRevert;
    }

    function setShouldWithdrawDefaultRevert(bool _shouldWithdrawDefaultRevert) public {
        shouldWithdrawDefaultRevert = _shouldWithdrawDefaultRevert;
    }

    function depositDefault(address, /* asset */ uint256 amount) public view returns (uint256) {
        if (shouldDepositDefaultRevert) revert("MockVaultManager: depositDefault revert");

        return amount;
    }

    function withdrawDefault(address, /* asset */ uint256 amount) public view returns (uint256) {
        if (shouldWithdrawDefaultRevert) revert("MockVaultManager: withdrawDefault revert");

        return amount;
    }

    // add this to be excluded from coverage report
    function test() public {}
}
