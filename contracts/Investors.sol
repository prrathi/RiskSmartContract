pragma solidity >=0.8.11;
import "./Platforms.sol";
import {Token} from "./Token.sol";

contract InvestorFactory is Platform{

    mapping (address => bytes32) addressToId; //address to id for platform
    mapping (bytes32 => address) idToAddress; //platform id to address here


    event newInvestor(bytes32 _hashUsername, uint256 _capital);

    function createInvestor(uint256 _capital, string memory username) public {
        // some indicator or capping factor would set finished to true
        require(Platform._getInvestorOpen());
        require(addressToId[msg.sender] == 0); //each account is associated with address 
        bytes32 hashUsername = keccak256(abi.encode(username));
        require(hashUsername != Platform.platform_id, "Username taken");
        require(Platform.investorExists[hashUsername] || Platform.participantExists[hashUsername], "Username taken");

        addressToId[msg.sender] = hashUsername;
        idToAddress[hashUsername] = msg.sender;
        investorIds.push(hashUsername);
        // uint _maxLoss = (_token1cnt + _token2cnt + _token3cnt); // * 1000;
        // uint tempamount = 0; //DO ACTUAL CALCULATIONS
        // usdt.approve(address(this), tempamount); //GET ACTUAL APPROVAL MECHANISM
        // usdt.transferFrom(msg.sender, address(this), tempamount);
        // _totalInvestorRisk += _maxLoss;
        uint256 numStake = _capital/Platform.token._getAmountPerStake();
        uint256 capital = numStake * Platform.token._getAmountPerStake();
        Platform.usdt.transferFrom(msg.sender, address(this), capital);
        Platform._initiateValue(hashUsername, capital, true, true, msg.sender);
        Platform._mint(msg.sender, numStake);
        emit newInvestor(hashUsername, capital);
    }
    
    function splitClaim(uint256 _claim, string memory username) internal {
        // splitting mechanism for now
        // fix floating point stuff later
        uint256 _unitClaim = 0 - _claim/Platform.token.totalSupply(); // how much each person has to pay -> won't be actual calculation
        for (uint i = 0; i < investorIds.length; i++) {
            Platform._updateValue(investorIds[i], _unitClaim*Platform.token.balanceOf(idToAddress[investorIds[i]]), false);
        }
        bytes32 hashUsername = keccak256(abi.encode(username));
        Platform._updateValue(hashUsername, _claim, true);
    }

    function changeStake(uint256 stake, address partner, string memory username) internal {
        // under current implementation if there was someone new, they would have to be the one to call this
        require(stake != 0);
        require(addressToId[partner] != 0);
        uint256 senderBalance = Platform.token.balanceOf(msg.sender);
        uint256 partnerBalance = Platform.token.balanceOf(partner);
        require(senderBalance + stake >= 0);
        require(partnerBalance - stake >= 0);
        require(Platform.token.allowance(partner, msg.sender) >= stake);
        // not sure how the actual transfer works
        // do we facilitate the creation of allowance and then transfer?
        // after that's done...
        if (addressToId[msg.sender] == 0) {
            bytes32 hashUsername = keccak256(abi.encode(username));
            require(hashUsername != Platform.platform_id, "Username taken");
            require(Platform.investorExists[hashUsername] || Platform.participantExists[hashUsername], "Username taken");

            addressToId[msg.sender] = hashUsername;
            idToAddress[hashUsername] = msg.sender;
            investorIds.push(hashUsername);

            Platform._initiateValue(hashUsername, 0, true, true, msg.sender);
            emit newInvestor(hashUsername, 0); 
        }
        Platform.token.transferFrom(partner, msg.sender, stake);
        Platform._initiateValue(addressToId[partner], stake*Platform.token._getAmountPerStake(), false, true, partner);
        Platform._initiateValue(addressToId[msg.sender], stake*Platform.token._getAmountPerStake(), true, true, partner);
    }

    function getValue() public view returns (uint256) {
        require(addressToId[msg.sender] != 0);
        bytes32 hashedUsername = addressToId[msg.sender];
        return Platform._getValue(hashedUsername);
    } 
}