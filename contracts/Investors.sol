pragma solidity >=0.5.17;

contract Investor {
    uint tokenonecnt;
    uint tokentwocnt;
    uint tokenthreecnt;
    uint32 totalcapital;
    uint32 maxloss;
    function initialize(uint32 capital, uint32 maxloss) public returns (bool);
    function change(uint32 diff) public returns (bool);
    function withdraw() public returns (bool);
    function getProfit() public returns (uint);
}