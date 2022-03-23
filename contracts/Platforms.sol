pragma solidity >=0.8.11;

contract Platform {
    uint totalCapital;
    uint time;

    function _startTimeCycle() private {
        require(time == 0); //for month cycle
        time = block.timestamp;
    }

    function _resetTimeCycle() private {
        time = 0;
    }

    function _getTime() public returns (uint) {
        bool valid = (block.timestamp - time) / 60 / 60 / 24 >= 30;
        if(!valid) {
            _resetTimeCycle();
        } 
        return time;
    }

    mapping (address => address) public participantIds;
    mapping (address => address) public investorIds; 
    mapping (address => uint) public participantSplits;
    mapping (address => uint) public investorSplits;
    

    function _updateCapital() public {
        //if a new investor joins update totalCapital
        //goes through each investor and updates the capital
    }
}