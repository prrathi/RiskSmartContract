// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {Admin} from "./Admin.sol";

contract InvestorFactory {

    mapping (address => bytes32) addressToId; //address to id for platform
    mapping (bytes32 => address) idToAddress; //platform id to address here

    event changeInvestor(bytes32 _hashUsername, uint256 tokens); // add type of token in future

    constructor(Admin _admin) Component(_admin){
        admin.initializeInvestor(this);
    }

    function createInvestor(uint256 _capital, bytes32 hashUsername) public {
        // some indicator or capping factor would set finished to true
        require(admin.Platform().isInvestorOpen, "currently closed");
        require(addressToId[msg.sender] == 0, "address already used"); //each account is associated with address 
        // bytes32 hashUsername = keccak256(abi.encode(username));
        // require(hashUsername != Platform.platform_id, "username taken");
        require(!admin.Platform().checkExists(hashUsername), "Username taken");

        addressToId[msg.sender] = hashUsername;
        idToAddress[hashUsername] = msg.sender;
        uint256 numStake = _capital/admin.Token()._getAmountPerStake();
        uint256 capital = numStake * admin.Token()._getAmountPerStake();
        // usdt.approve(address(this), _capital); //GET ACTUAL APPROVAL MECHANISM
        admin.Currency().transferFrom(msg.sender, address(this), capital);
        admin.Platform()._initiateValue(hashUsername, capital, true, true, msg.sender);
        admin.Platform()._mint(msg.sender, numStake);
        emit changeInvestor(hashUsername, numStake);
    }
    

    function changeStake(address receiver, uint256 stake, address partner, bytes32 hashUsername) public onlyTrading {
        // under current implementation if there was someone new, they would have to be the one to call this
        require(stake != 0);
        require(addressToId[partner] != 0);
        uint256 senderBalance = admin.Token().balanceOf(receiver);
        uint256 partnerBalance = admin.Token().balanceOf(partner);
        require(senderBalance + stake >= 0);
        require(partnerBalance - stake >= 0);
        
        if (addressToId[receiver] == 0) {
            // require(hashUsername != admin.Platform().admin.Platform()_id, "Username taken");
            require(!admin.Platform().checkExists(hashUsername), "Username taken");
            addressToId[receiver] = hashUsername;
            idToAddress[hashUsername] = msg.sender;
            admin.Platform()._initiateValue(hashUsername, 0, true, true, msg.sender);
        } else {
            require(hashUsername == addressToId[msg.sender]);
        }

        // require(admin.Platform().token.allowance(partner, receiver) >= stake);
        // not sure how the actual transfer works
        // do we facilitate the creation of allowance and then transfer?

        // alternate method: burn one person's and mint another person's
        admin.Platform()._burn(partner, stake);
        admin.Platform()._mint(receiver, stake);
        admin.Platform()._initiateValue(addressToId[partner], stake*admin.Platform().token._getAmountPerStake(), false, true, partner);
        admin.Platform()._initiateValue(addressToId[receiver], stake*admin.Platform().token._getAmountPerStake(), true, true, partner);
        emit changeInvestor(hashUsername, stake);
        emit changeInvestor(addressToId[partner], 0 - stake);
    }

    function getValue() public view returns (uint256) {
        require(addressToId[msg.sender] != 0);
        bytes32 hashedUsername = addressToId[msg.sender];
        return admin.Platform()._getValue(hashedUsername);
    } 
}