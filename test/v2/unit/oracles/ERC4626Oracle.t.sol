// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC4626DelayedOracle} from "@level/src/v2/oracles/ERC4626DelayedOracle.sol";
import {ERC4626OracleFactory} from "@level/src/v2/oracles/ERC4626OracleFactory.sol";
import {MockERC4626} from "@level/test/v2/mocks/MockERC4626.sol";
import {MockToken} from "@level/test/v2/mocks/MockToken.sol";

contract ERC4626DelayedOracleTest is Test {
    ERC4626DelayedOracle oracle;
    ERC4626OracleFactory factory;
    MockERC4626 mockVault;

    uint256 constant delay = 1 hours; // 1 hour delay for example

    function setUp() public {
        MockToken mockToken = new MockToken("MockToken", "MockToken", 18, address(this));
        mockVault = new MockERC4626(mockToken);
        factory = new ERC4626OracleFactory();

        mockVault.setConvertToAssetsOutput(100);
        oracle = new ERC4626DelayedOracle(mockVault, delay);
    }

    function testConstructor() public view {
        assertEq(address(oracle.vault()), address(mockVault));
        assertEq(oracle.delay(), delay);
    }

    function testDecimals() public view {
        assertEq(oracle.decimals(), 18);
    }

    function testDescription() public view {
        assertEq(oracle.description(), "Chainlink-compliant ERC4626 Oracle");
    }

    function testVersion() public view {
        assertEq(oracle.version(), 1);
    }

    function testLatestRoundData() public {
        mockVault.setConvertToAssetsOutput(100);
        (, int256 price, uint256 startedAt, uint256 updatedAt,) = oracle.latestRoundData();
        assertEq(price, 100);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
    }

    function testPriceUpdateDelay() public {
        mockVault.setConvertToAssetsOutput(100);
        (, int256 price, uint256 startedAt, uint256 updatedAt,) = oracle.latestRoundData();
        assertEq(price, 100);
        assertEq(oracle.nextPrice(), 100);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);

        // Test that we get price if before delay expires
        mockVault.setConvertToAssetsOutput(200);
        vm.warp(block.timestamp + delay + 1);

        oracle.update();
        uint256 previousUpdatedAt = oracle.updatedAt();
        (, price, startedAt, updatedAt,) = oracle.latestRoundData();
        assertEq(price, 100);
        assertEq(oracle.nextPrice(), 200);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);

        // Test that we get nextPrice if delay expires
        mockVault.setConvertToAssetsOutput(300);
        vm.warp(block.timestamp + delay + 1);
        (, price, startedAt, updatedAt,) = oracle.latestRoundData();
        assertEq(price, 200);
        assertEq(oracle.nextPrice(), 200);
        assertEq(startedAt, previousUpdatedAt);
        assertEq(updatedAt, previousUpdatedAt);
    }

    function testPriceUpdateDelay_failsEarly() public {
        mockVault.setConvertToAssetsOutput(100);
        vm.warp(block.timestamp + delay - 1);
        vm.expectRevert("Can only update after the delay is passed");
        oracle.update();
    }

    function testPriceUpdate_returnsOldPriceIfNotUpdated() public {
        mockVault.setConvertToAssetsOutput(100);
        uint256 initializedAt = block.timestamp;

        (, int256 price, uint256 startedAt, uint256 updatedAt,) = oracle.latestRoundData();
        assertEq(price, 100);
        assertEq(startedAt, initializedAt);
        assertEq(updatedAt, initializedAt);

        mockVault.setConvertToAssetsOutput(200);
        vm.warp(block.timestamp + delay + 1);
        (, price, startedAt, updatedAt,) = oracle.latestRoundData();
        assertEq(price, 100);
        assertEq(startedAt, initializedAt);
        assertEq(updatedAt, initializedAt);
    }

    function testCreateOracle() public {
        oracle = factory.createDelayed(mockVault, delay);
        assertEq(address(oracle.vault()), address(mockVault));
        assertEq(oracle.delay(), delay);
    }
}
