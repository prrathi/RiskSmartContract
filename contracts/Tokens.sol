pragma solidity >=0.8.11;
import "./Platforms.sol";

contract TokenOne {

function totalSupply() public view returns (uint256) {
    
}
function balanceOf(address tokenOwner) public view returns (uint);
function allowance(address tokenOwner, address spender)
public view returns (uint);
function transfer(address to, uint tokens) public returns (bool);
function approve(address spender, uint tokens)  public returns (bool);
function transferFrom(address from, address to, uint tokens) public returns (bool);

}


contract TokenTwo {

function totalSupply() public view returns (uint256);
function balanceOf(address tokenOwner) public view returns (uint);
function allowance(address tokenOwner, address spender)
public view returns (uint);
function transfer(address to, uint tokens) public returns (bool);
function approve(address spender, uint tokens)  public returns (bool);
function transferFrom(address from, address to, uint tokens) public returns (bool);

}

contract TokenThree {

function totalSupply() public view returns (uint256);
function balanceOf(address tokenOwner) public view returns (uint);
function allowance(address tokenOwner, address spender)
public view returns (uint);
function transfer(address to, uint tokens) public returns (bool);
function approve(address spender, uint tokens)  public returns (bool);
function transferFrom(address from, address to, uint tokens) public returns (bool);

}
