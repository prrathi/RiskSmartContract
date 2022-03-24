pragma solidity >=0.5.17;
import {Platform} from "./Platforms.sol";
import {InvestorFactory} from "./Investors.sol";

contract ParticipantFactory{

    struct Participant {
        uint prerisk;
        uint numClaims;
        uint totalClaims;
        uint value;
    }

    mapping (address => bytes32) addressToId;
    mapping (bytes32 => Participant) idToParticipant;

    event NewParticipant(bytes32 _hashUsername, uint _prerisk, uint _value);

    // Participant[] public participants;
    function createParticipant(uint _prerisk, /*uint _numClaims, uint _totalClaims,*/ uint _value, string memory username) public {
        require(Platform._getParticipantOpen());
        require(addressToId[msg.sender] == 0);
        bytes32 hashUsername = keccak256(abi.encode(username));
        require(hashUsername !=Platform.platform_id);
        require(idToParticipant[hashUsername] == 0);
        addressToId[msg.sender] = hashUsername;
        idToParticipant[hashUsername] = Participant(_prerisk, 0, 0, _value);

        // get max loss for participant, aka sum of premiums
        // uint256 totalPremium = premium * _prerisk * Platform.token.getDuration() / Platform.token.getPaymentFreq();
        // then require user to give totalPremium as allowance to this platform, which then takes what's needed later

        emit NewParticipant(hashUsername, _prerisk, _value);
    }
    // need indicator for when opening period is finished to do calculations

    function registerClaim(uint _claim, string memory username) public {
        require(addressToId[msg.sender] != 0);
        string memory hashUsername = keccak256(username);
        require(hashUsername == addressToId[msg.sender]);
        Participant storage myParticipant = idToParticipant[hashUsername]; //storage means pass by reference
        myParticipant.numClaims++;
        myParticipant.totalClaims += _claim;
        InvestorFactory.splitClaim(_claim, hashUsername);
    }

}