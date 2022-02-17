pragma solidity >=0.5.17;
import "./Platforms.sol";
import "./Investors.sol";

contract ParticipantFactory is Platform, InvestorFactory {

    struct Participant {
        uint prerisk;
        uint numClaims;
        uint totalClaims;
        uint value;
    }

    mapping (address => uint) participantToId;

    event NewParticipant(uint _id, uint _prerisk, uint _numClaims, uint _totalClaims, uint _value);

    Participant[] public participants;
    function createParticipant(uint _prerisk, uint _numClaims, uint _totalClaims, uint _value) public {
        require(participantToId[msg.sender] == 0);
        participants.push(Participant(_prerisk, _numClaims, _totalClaims, _value));
        uint _id = participants.length;
        participantToId[msg.sender] = _id;
        // perform some calculations to determine risk
        // setParticipantRisk(_riskMetric)
        emit NewParticipant(_id, _prerisk, _numClaims, _totalClaims, _value);
    }

    function registerClaim(uint _claim) public {
        require(participantToId[msg.sender] != 0);
        Participant storage myParticipant = participants[participantToId[msg.sender]-1]; //storage means pass by reference
        myParticipant.numClaims++;
        myParticipant.totalClaims += _claim;
        splitClaim(_claim);
    }

}