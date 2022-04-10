// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Component} from "./Component.sol";
import {Admin} from "./Admin.sol";

contract Token is IERC20, Component{

    uint256 public constant MIN_SCALE = 1e8;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string internal _name;
    uint256 internal _totalSupply; // some constant * WadMath.WAD/MIN_SCALE total value held in token divided by value per stake
    uint256 internal constant _amountPerStake = 100;

constructor(Admin admin_, string memory name_) Component(admin_) {
    require(msg.sender == address(this)); // only contract can initialize
    _name = name_;
}

function name() public view returns (string memory) {
    return _name;
}

function totalSupply() public view override returns (uint256) {
    return _totalSupply;
}

function balanceOf(address tokenOwner) public view override returns (uint256){
    uint256 principalBalance = _balances[tokenOwner];
    return principalBalance;
}

function allowance(address tokenOwner, address spender) public view override returns (uint) {
    return _allowances[tokenOwner][spender];
}

function transfer(address to, uint tokens) public override returns (bool) {
    _transfer(msg.sender, to, tokens);
    return true;
}

function approve(address spender, uint tokens)  public override returns (bool){
    _approve(msg.sender, spender, tokens);
    return true;
}

function transferFrom(address from, address to, uint tokens) public override returns (bool) {
    _transfer(from, to, tokens);
    uint256 currentAllowance = _allowances[from][msg.sender];
    require(currentAllowance >= tokens, "transfer amount exceeds allowance");
    _approve(from, msg.sender, currentAllowance - tokens);
    return true;
}

function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
  {
    uint256 currentAllowance = _allowances[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "EToken: decreased allowance below zero");
    _approve(msg.sender, spender, currentAllowance - subtractedValue);

    return true;
  }

function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "can't approve from the zero address");
    require(spender != address(0), "can't approve to the zero address");

    _allowances[owner][spender] = amount;
    // emit Approval(owner, spender, amount);
  }

  function _transfer( address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "transfer from the zero address");
    require(recipient != address(0), "transfer to the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;
  }

  function _mint(address account, uint256 amount) external onlyPlatform {
    require(account != address(0), "mint to the zero address");

    _totalSupply += amount;
    _balances[account] += amount;
    // emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) external onlyPlatform {
    require(account != address(0), "Burn from the zero address");
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "Burn amount exceeds balance");
    _balances[account] = accountBalance - amount;
    _totalSupply -= amount;
    // emit Transfer(address(0), account, amount);
  }

  function _getAmountPerStake() public pure returns (uint256) {
    return _amountPerStake;
  }

}
