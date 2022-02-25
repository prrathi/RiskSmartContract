pragma solidity >=0.5.17;
import "./Platforms.sol";
import "./IERC20.sol";

contract InvestorFactory is Platform{

    // put these in platforms.sol?
    // fillerValues, use extra zeroes as equivalent to decimal points
    uint token1ratio = 1000; //100% stop loss ratio
    uint token2ratio = 2000; 
    uint token3ratio = 3000; 

    // change to three investor structs, each with different tokens
    // make different contract for each token type

    struct Investor {
        uint256 token1cnt; //1 token = $1000 max loss -> 1000, #tokens = $maxloss
        uint256 token2cnt;
        uint256 token3cnt;
        uint256 maxLoss; //
        uint256 currLoss;
        uint256 value;
        // each token represents quantity of different ratioed (capital:maxloss) investments
        // can set temporary constraint that investor can't have multiple types of tokens
    }
    uint _totalInvestorRisk;
    bool finished = false;
    bool finishedAlready = false;

    IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address

    mapping (address => uint) investorToId;

    event newInvestor(uint _id, uint _token1cnt, uint _token2cnt, uint _token3cnt);

    Investor[] public investors;

    function createInvestor(uint _token1cnt, uint _token2cnt, uint _token3cnt ) public {
        require(investorToId[msg.sender] == 0); //each account is associated with address 
        uint _maxLoss = (_token1cnt + _token2cnt + _token3cnt); // * 1000;
        uint tempamount = 0; //DO ACTUAL CALCULATIONS
        usdt.approve(address(this), tempamount); //GET ACTUAL APPROVAL MECHANISM
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

    // function change(uint32 diff) public returns (bool);
    // function withdraw() public returns (bool);
    function getProfit() public view returns (uint) {
        require(investorToId[msg.sender] != 0);
        Investor memory iTemp = investors[investorToId[msg.sender]-1];
        return iTemp.value - iTemp.currLoss;
    }
}