pragma solidity >=0.8.11;

contract Platform{
    uint totalParticipantRisk;
    uint totalInvestorRisk;
    uint totalPlatformRisk;
    uint startTime;
    uint capital;

    function startTimeCycle() private {
        require(startTime == 0); //for month cycle
        startTime = block.timestamp;
    }

    function checkValidTime() internal returns (bool) { 
        bool valid = (block.timestamp - startTime) / 60 / 60 / 24 >= 30;
        if (valid) {
            resetTimeCycle();
        } 
        return valid;
    } 

    function setParticipantRisk(uint _addRisk) internal {
        totalParticipantRisk += _addRisk;
    }

    function setInvestorRisk(uint _totalInvestorRisk) internal {
        totalInvestorRisk += _totalInvestorRisk;
        if (totalPlatformRisk != 0) {
            capital = capital + totalPlatformRisk;
        }
        totalPlatformRisk = totalParticipantRisk - totalInvestorRisk; 
    }

    function resetTimeCycle() private {
        startTime = 0;
    }

}