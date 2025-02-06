// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {LevelReserveLensChainlinkOracle} from "../../../src/lens/LevelReserveLensChainlinkOracle.sol";
import {LevelReserveLens} from "../../../src/lens/LevelReserveLens.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract MockLvlUSD is ERC20 {
    constructor() ERC20("Level USD", "lvlUSD") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

contract MockLevelReserveLens {
    uint256 private price;
    bool private shouldRevert;

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function getReservePrice() external view returns (uint256) {
        require(!shouldRevert, "MockLens: Forced revert");
        return price;
    }
}

contract LevelReserveLensChainlinkOracleTest is Test {
    LevelReserveLensChainlinkOracle public oracle;
    MockLevelReserveLens public lens;
    MockLvlUSD public lvlUSD;

    address public admin = address(1);
    address public pauser = address(2);

    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        lvlUSD = new MockLvlUSD();
        lens = new MockLevelReserveLens();

        oracle = new LevelReserveLensChainlinkOracle(admin, pauser, address(lens), address(lvlUSD));
    }

    function test_constructor() public {
        assertEq(oracle.hasRole(oracle.DEFAULT_ADMIN_ROLE(), admin), true);
        assertEq(oracle.hasRole(oracle.PAUSER_ROLE(), pauser), true);
        assertEq(address(oracle.lens()), address(lens));
        assertEq(address(oracle.lvlusd()), address(lvlUSD));
    }

    function test_constructor_zeroAddressAdmin() public {
        vm.expectRevert("Address cannot be zero");
        new LevelReserveLensChainlinkOracle(address(0), pauser, address(lens), address(lvlUSD));
    }

    function test_constructor_zeroAddressLens() public {
        vm.expectRevert("Address cannot be zero");
        new LevelReserveLensChainlinkOracle(admin, pauser, address(0), address(lvlUSD));
    }

    function test_constructor_zeroAddressToken() public {
        vm.expectRevert("Address cannot be zero");
        new LevelReserveLensChainlinkOracle(admin, pauser, address(lens), address(0));
    }

    function test_decimals() public {
        assertEq(oracle.decimals(), 18);
    }

    function test_description() public {
        assertEq(oracle.description(), "Chainlink interface compliant oracle for Level USD");
    }

    function test_version() public {
        assertEq(oracle.version(), 0);
    }

    function test_latestRoundData() public {
        uint256 expectedPrice = 1.2e18;
        lens.setPrice(expectedPrice);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        assertEq(roundId, 0);
        assertEq(answer, int256(expectedPrice));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }

    function test_latestRoundData_WhenPaused() public {
        vm.prank(pauser);
        oracle.setPaused(true);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        assertEq(roundId, 0);
        assertEq(answer, 1e18); // Default $1 price
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }

    function test_latestRoundData_whenLensReverts() public {
        lens.setShouldRevert(true);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        assertEq(roundId, 0);
        assertEq(answer, 1e18); // Default $1 price
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }

    function test_getRoundData() public {
        uint256 expectedPrice = 1.2e18;
        lens.setPrice(expectedPrice);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.getRoundData(0);

        assertEq(roundId, 0);
        assertEq(answer, int256(expectedPrice));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }

    function test_setPaused() public {
        vm.prank(pauser);
        oracle.setPaused(true);

        assertTrue(oracle.paused());

        vm.prank(pauser);
        oracle.setPaused(false);

        assertFalse(oracle.paused());
    }

    function test_setPaused_OnlyPauser() public {
        vm.startPrank(address(0xdead));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(0xdead), oracle.PAUSER_ROLE()
            )
        );
        oracle.setPaused(true);
    }

    function test_defaultRoundData() public {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.defaultRoundData();

        assertEq(roundId, 0);
        assertEq(answer, 1e18); // $1 with 18 decimals
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }
}
