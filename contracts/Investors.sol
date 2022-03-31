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
        uint256 numStake = _capital/Platform.token._getAmountPerStake();
        uint256 capital = numStake * Platform.token._getAmountPerStake();
        // usdt.approve(address(this), _capital); //GET ACTUAL APPROVAL MECHANISM
        Platform.usdt.transferFrom(msg.sender, address(this), capital);
        Platform._initiateValue(hashUsername, capital, true, true, msg.sender);
        Platform._mint(msg.sender, numStake);
        emit newInvestor(hashUsername, capital);
    }
    
    function splitClaim(string memory username) internal {
        // splitting mechanism for now
        // fix floating point stuff later
        uint256 outstandingClaim = Platform.claimAmount;
        uint256 unitClaim = Platform.claimAmount/Platform.token.totalSupply(); // how much each person has to pay -> won't be actual calculation
        uint256 remainingCapital = 0;
        for (uint i = 0; i < Platform.investorIds.length; i++) {
            bytes32 investorId = Platform.investorIds[i];
            if (Platform.investorRisk[investorId] >= unitClaim*Platform.token.balanceOf(idToAddress[investorIds[i]])) {
                Platform._updateValue(investorIds[i], unitClaim*Platform.token.balanceOf(idToAddress[investorIds[i]]), false);
                Platform.investorRisk[investorId] -= unitClaim*Platform.token.balanceOf(idToAddress[investorIds[i]]);
                outstandingClaim -= unitClaim*Platform.token.balanceOf(idToAddress[investorIds[i]]);
                remainingCapital += Platform.investorRisk[investorId];
            } else{
                if (Platform.investorRisk[investorId] > 0) {
                    Platform._updateValue(investorIds[i], Platform.investorRisk[investorId], false);
                    Platform.investorRisk[investorId] = 0;
                    outstandingClaim -= Platform.investorRisk[investorId];
                }
            }
        }
        if (remainingCapital <= outstandingClaim) {
            for (uint i = 0; i < Platform.investorIds.length; i++) {
                Platform.investorRisk[Platform.investorIds[i]] = 0;
            }
            Platform._changeTreasury(outstandingClaim - remainingCapital, false);
        } else{
            for (uint i = 0; i < Platform.investorIds.length; i++) {
                Platform.investorRisk[Platform.investorIds[i]] = Platform.investorRisk[Platform.investorIds[i]] * (remainingCapital - outstandingClaim) / remainingCapital;
            }
        }
        bytes32 hashUsername = keccak256(abi.encode(username));
        Platform._updateValue(hashUsername, Platform.claimAmount, true);
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