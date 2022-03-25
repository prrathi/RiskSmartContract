pragma solidity >=0.8.11;
import "./Platforms.sol";
// import "./IERC20.sol";
import {Token} from "./Token.sol";

contract InvestorFactory is Platform{

    struct Investor {
        // only have one type of token for now
        uint256 safeCapital;
        uint256 accPremiums;
    }

    // mapping(address => uint256) investorPremiums;
    // mapping(address => uint256) investorSplit;

    mapping (address => bytes32) addressToId;
    mapping (bytes32 => Investor) idToInvestor;
    mapping (bytes32 => address) idToAddress;

    bytes32 [] private investorIds;

    event newInvestor(bytes32 _hashUsername, uint256 _capital);

    function createInvestor(uint256 _capital, string memory username) public {
        // some indicator or capping factor would set finished to true
        require(Platform._getInvestorOpen());
        require(addressToId[msg.sender] == 0); //each account is associated with address 
        bytes32 hashUsername = keccak256(abi.encode(username));
        require(hashUsername != Platform.platform_id, "Username taken");
        require(idToAddress[hashUsername] == 0, "Username taken");

        uint256 potentialLoss = _capital/Platform.token.getMaxLossRatio();

        addressToId[msg.sender] = hashUsername;
        idToInvestor[hashUsername] = Investor(_capital-potentialLoss, 0);
        idToAddress[hashUsername] = msg.sender;
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
        uint256 _unitClaim = 0 - _claim/Platform.token.totalSupply(); // how much each person has to pay -> won't be actual calculation
        for (uint i = 0; i < investorIds.length; i++) {
            Platform._updateValue(investorIds[i], _unitClaim*Platform.token.balanceOf(idToAddress[investorIds[i]]));
        }
        bytes32 hashUsername = keccak256(abi.encode(username));
        Platform._updateValue(hashUsername, _claim);
    }

    function changeStake(uint256 changeCapital, address partner, string memory username) internal {
        // under current implementation if there was someone new, they would have to be the one to call this
        require(changeCapital != 0);
        require(addressToId[partner] != 0);
        uint256 stake = changeCapital/Platform.token.getMaxLossRatio();
        require(Platform.token.balanceOf(msg.sender) + stake >= 0);
        require(Platform.token.balanceOf(partner) - stake >= 0);
        // not sure how the actual transfer works
        // do we facilitate the creation of allowance and then transfer?
        // after that's done...
        if (addressToId[msg.sender] == 0) {
            bytes32 hashUsername = keccak256(abi.encode(username));
            require(hashUsername != Platform.platform_id, "Username taken");
            require(idToInvestor[hashUsername].safeCapital != 0, "Username taken");

            addressToId[msg.sender] = hashUsername;
            idToInvestor[hashUsername] = Investor(0, 0);
            idToAddress[hashUsername] = msg.sender;
            investorIds.push(hashUsername);

            Platform._updateValue(hashUsername, 0);
            emit newInvestor(hashUsername, 0); 
        }
        Investor storage iPartner = idToInvestor[addressToId[partner]];
        Investor storage i = idToInvestor[addressToId[msg.sender]];
        if (changeCapital > 0) {
            // dostuff
        } else {
            // dostuff
        }
    }

    function getValue() public view returns (uint256) {
        require(addressToId[msg.sender] != 0);
        bytes32 hashedUsername = addressToId[msg.sender];
        return idToInvestor[hashedUsername].safeCapital + Platform._getValue(hashedUsername);
    } 
}