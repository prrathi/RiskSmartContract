pragma solidity >=0.5.17;
import "./Platforms.sol";
import "./IERC20.sol";

contract InvestorFactory is Platform {


    struct Investor {
        uint256 maxLoss; 
        uint256 capital;
        uint256 accPremiums;
        uint256 split;
    }

    mapping(address => uint256) investorPremiums;
    mapping(address => uint256) investorSplit;


    uint _totalInvestorRisk;
    bool finished = false;
    bool finishedAlready = false;

    IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address

    mapping (address => uint) investorToId;

    event newInvestor(uint _id, uint _token1cnt, uint _token2cnt, uint _token3cnt);

    Investor[] public investors;

    function createInvestor(uint _token1cnt, uint _token2cnt, uint _token3cnt) public {
        require(investorToId[msg.sender] == 0); //each account is associated with address 
        uint _maxLoss = (_token1cnt + _token2cnt + _token3cnt); // * 1000;
        uint tempamount = 0; //DO ACTUAL CALCULATIONS
        // usdt.approve(address(this), tempamount); //GET ACTUAL APPROVAL MECHANISM
        usdt.transferFrom(msg.sender, address(this), tempamount);
        investors.push(Investor(_token1cnt, _token2cnt, _token3cnt, _maxLoss, 0, 0));
        uint _id = investors.length;
        investorToId[msg.sender] = _id;
        // some indicator or capping factor would set finished to true
        _totalInvestorRisk += _maxLoss;
        if (finished && !finishedAlready) {
            setInvestorRisk(_totalInvestorRisk);
            finishedAlready = true;
        }
        emit newInvestor(_id, _token1cnt, _token2cnt, _token3cnt);
    }
    
    function splitClaim(uint _claim) internal {
        //dostuff
    }

    function withdraw(uint32 amount) public{
        
    }

    function change(uint32 amount, string mode) public{
        //NA
    }
/NA/
    // function change(uint32 diff) public returns (bool);
    // function withdraw() public returns (bool);
    function getProfit() public view returns (uint) {
        require(investorToId[msg.sender] != 0);
        Investor memory iTemp = investors[investorToId[msg.sender]-1];
        return iTemp.value - iTemp.currLoss;
    }

    function getPremium() public returns (uint) {
        
    }
}        require()investorToID[]msg.sender != 0;