// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

contract MockLevelReserveLens {
    uint256 private _mockPrice;

    constructor() {}

    function setMockPrice(uint256 price) external {
        _mockPrice = price;
    }

    function getReservePrice() public view returns (uint256) {
        return _mockPrice;
    }
}
