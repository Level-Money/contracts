// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {MathLib} from "@level/src/v2/common/libraries/MathLib.sol";

contract Utils is Test {
    string internal constant MAINNET_RPC_KEY = "MAINNET_RPC_URL";

    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    // create users with 100 ETH balance each
    function createUsers(uint256 userNum) external returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = this.getNextUserAddress();
            vm.deal(user, 100 ether);
            users[i] = user;
        }

        return users;
    }

    // move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }

    function forkMainnet() public returns (uint256 forkId) {
        forkId = vm.createFork(vm.envString(MAINNET_RPC_KEY));
        vm.selectFork(forkId);
    }

    function forkMainnet(uint256 blockNumber) public returns (uint256 forkId) {
        forkId = vm.createFork(vm.envString(MAINNET_RPC_KEY), blockNumber);
        vm.selectFork(forkId);
    }

    function startFork(string memory rpcKey) external returns (uint256 forkId) {
        forkId = vm.createFork(vm.envString(rpcKey));
        vm.selectFork(forkId);
    }

    function startFork(string memory rpcKey, uint256 blockNumber) external returns (uint256 forkId) {
        forkId = vm.createFork(vm.envString(rpcKey), blockNumber);
        vm.selectFork(forkId);
    }

    function _scheduleAdminAction(address admin, address _timelock, address target, bytes memory data)
        internal
        returns (bytes32)
    {
        vm.startPrank(admin);

        TimelockController timelock = TimelockController(payable(_timelock));

        timelock.schedule(target, 0, data, bytes32(0), 0, 5 days);

        bytes32 id = timelock.hashOperation(target, 0, data, bytes32(0), 0);

        vm.stopPrank();

        return id;
    }

    function _executeAdminAction(address admin, address _timelock, address target, bytes memory data) internal {
        vm.startPrank(admin);

        TimelockController timelock = TimelockController(payable(_timelock));

        timelock.execute(target, 0, data, bytes32(0), 0);
        vm.stopPrank();
    }

    function _scheduleAndExecuteAdminAction(address admin, address _timelock, address target, bytes memory data)
        internal
    {
        vm.startPrank(admin);

        TimelockController timelock = TimelockController(payable(_timelock));

        timelock.schedule(target, 0, data, bytes32(0), 0, 5 days);

        vm.warp(block.timestamp + 5 days);

        timelock.execute(target, 0, data, bytes32(0), 0);
        vm.stopPrank();
    }

    function _scheduleAndExecuteAdminActionBatch(
        address admin,
        address _timelock,
        address[] memory targets,
        bytes[] memory payloads
    ) internal {
        if (targets.length != payloads.length) {
            revert("Targets and payloads must have the same length");
        }

        uint256[] memory values = new uint256[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            values[i] = 0;
        }

        vm.startPrank(admin);

        TimelockController timelock = TimelockController(payable(_timelock));

        timelock.scheduleBatch(targets, values, payloads, bytes32(0), 0, 5 days);

        vm.warp(block.timestamp + 5 days);

        timelock.executeBatch(targets, values, payloads, bytes32(0), 0);
        vm.stopPrank();
    }

    function _adjustAmount(uint256 amount, address from, address to) internal view returns (uint256) {
        ERC20 fromAsset = ERC20(from);
        ERC20 toAsset = ERC20(to);

        if (from == to || fromAsset.decimals() == toAsset.decimals()) {
            return amount;
        }
        uint256 result = MathLib.mulDivDown(amount, 10 ** toAsset.decimals(), 10 ** fromAsset.decimals());
        return result;
    }

    /// Useful function to check balance of tokens that don't conform
    /// to the ERC20 standard
    function checkBalance(address token, address account) external view returns (uint256) {
        // The function selector for balanceOf(address)
        bytes4 selector = bytes4(keccak256("balanceOf(address)"));

        // Encode the function call
        bytes memory data = abi.encodeWithSelector(selector, account);

        // Make the call
        (bool success, bytes memory returnData) = token.staticcall(data);

        require(success, "Balance check failed");

        // Decode the result
        return abi.decode(returnData, (uint256));
    }

    // Apply a percentage to an amount. .01e18 is 1%
    function _applyPercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return MathLib.mulDivDown(amount, percentage, 1e18);
    }

    // add this to be excluded from coverage report
    function test() public {}
}
