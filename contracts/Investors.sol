pragma solidity >=0.5.17;
import {Platform} from "./Platforms.sol";
// import "./IERC20.sol";
import {Token} from "./Token.sol";

contract InvestorFactory{

    struct Investor {
        // only have one type of token for now
        uint256 safeCapital;
        uint256 accPremiums;
    }

    // mapping(address => uint256) investorPremiums;
    // mapping(address => uint256) investorSplit;

    mapping (address => bytes32) addressToId;
    mapping (bytes32 => Investor) idToInvestor;
    mapping (bytes32 => address) investorToAddress;

    bytes32 [] private investorIds;

    event newInvestor(bytes32 _hashUsername, uint256 _capital);

    function createInvestor(uint256 _capital, string memory username) public {
        // some indicator or capping factor would set finished to true
        require(Platform._getInvestorOpen());
        require(addressToId[msg.sender] == 0); //each account is associated with address 
        bytes32 hashUsername = keccak256(abi.encode(username));
        require(hashUsername != Platform.platform_id);
        require(idToInvestor[hashUsername] == 0);

        uint256 potentialLoss = _capital/Token.maxLossRatio_;

        addressToId[msg.sender] = hashUsername;
        idToInvestor[hashUsername] = Investor(_capital-potentialLoss, 0);
        investorToAddress[hashUsername] = msg.sender;
        investorIds.push(hashUsername);
        // uint _maxLoss = (_token1cnt + _token2cnt + _token3cnt); // * 1000;
        // uint tempamount = 0; //DO ACTUAL CALCULATIONS
        // usdt.approve(address(this), tempamount); //GET ACTUAL APPROVAL MECHANISM
        // usdt.transferFrom(msg.sender, address(this), tempamount);
        // _totalInvestorRisk += _maxLoss;

        Platform.usdt.transferFrom(msg.sender, address(this), potentialLoss);
        Platform._updateValue(hashUsername, potentialLoss);
        emit newInvestor(hashUsername, _capital);
    }
    
    function splitClaim(uint256 _claim, string memory username) internal {
        // splitting mechanism for now
        // fix floating point stuff later
        uint256 _unitClaim = -1 * _claim/Platform.token.totalSupply(); // how much each person has to pay -> won't be actual calculation
        for (uint i = 0; i < investorIds.length; i++) {
            Platform._updateValue(investorIds[i], _unitClaim*Platform.token.balanceOf(investorToAddress[investorIds[i]]));
        }
        Platform._updateValue(username, _claim);
    }

    // function withdraw(uint32 amount) public{
        
    // }

    // function change(uint32 amount) public{
     
    // }

    // function change(uint32 diff) public returns (bool);
    // function withdraw() public returns (bool);
    function getValue() public view returns (uint256) {
        require(addressToId[msg.sender] != 0);
        string memory username = addressToId[msg.sender];
        return idToInvestor[username].capital + Platform._balances[username];
    }

    function getPremium() public returns (uint) {
        
    }
}