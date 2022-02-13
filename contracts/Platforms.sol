pragma solidity >=0.8.11;
import "./Investors.sol";
import "./Participants.sol";

contract Platform{
    uint32 totalSupply;
    uint32 investorsCapital;
    uint startTime;
    uint currentTime;
    function updateTimestamp() public {
        currentTime = block.timestamp;
    }
    function recordClaim()

    Investor[] investors; 
    Participant[] participants;



}