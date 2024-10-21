// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock aToken contract with rebasing (accrue interest) mechanism
contract MockAToken is IERC20 {
    uint256 public constant INITIAL_EXCHANGE_RATE = 1e18; // 1:1 initial exchange rate
    uint256 public exchangeRate;
    mapping(address => uint256) private _userBalances;
    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        exchangeRate = INITIAL_EXCHANGE_RATE;
    }

    function mint(address account, uint256 amount) external {
        uint256 aTokenAmount = (amount * INITIAL_EXCHANGE_RATE) / exchangeRate;
        _userBalances[account] += aTokenAmount;
        _totalSupply += aTokenAmount;
        emit Transfer(address(0), account, aTokenAmount);
    }

    function burn(address account, uint256 amount) external {
        uint256 aTokenAmount = (amount * INITIAL_EXCHANGE_RATE) / exchangeRate;
        require(_userBalances[account] >= aTokenAmount, "Insufficient balance");
        _userBalances[account] -= aTokenAmount;
        _totalSupply -= aTokenAmount;
        emit Transfer(account, address(0), aTokenAmount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return (_userBalances[account] * exchangeRate) / INITIAL_EXCHANGE_RATE;
    }

    function totalSupply() public view override returns (uint256) {
        return (_totalSupply * exchangeRate) / INITIAL_EXCHANGE_RATE;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 aTokenAmount = (amount * INITIAL_EXCHANGE_RATE) / exchangeRate;
        require(
            _userBalances[msg.sender] >= aTokenAmount,
            "Insufficient balance"
        );
        _userBalances[msg.sender] -= aTokenAmount;
        _userBalances[recipient] += aTokenAmount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return type(uint256).max; // Simplified: always approve max
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        return true; // Simplified: always approve
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 aTokenAmount = (amount * INITIAL_EXCHANGE_RATE) / exchangeRate;
        require(_userBalances[sender] >= aTokenAmount, "Insufficient balance");
        _userBalances[sender] -= aTokenAmount;
        _userBalances[recipient] += aTokenAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Simulate interest accrual
    function accrueInterest(uint256 interestRate) external {
        // interestRate is in basis points (1% = 100)
        exchangeRate += (exchangeRate * interestRate) / 10000;
    }

    // add this to be excluded from coverage report
    function test() public {}
}
