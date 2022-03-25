pragma solidity >=0.8.11;
import {IERC20} from "../interfaces/IERC20.sol";
import {Token} from "./Token.sol";

contract Platform {
    uint totalCapital;
    uint time;
    bool isInvestorOpen;
    bool isParticipantOpen;

    bytes32 internal constant platform_id = keccak256("PLATFORM");
    IERC20 internal usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address

    mapping(bytes32 => uint256) private _balances;

    uint256 dayFreq = 1*24*24*60; // payments every day
    uint256 duration = 30*24*24*60; // duration is month

    Token internal token = new Token("sampleToken", 5, dayFreq, duration);

    function _updateValue(bytes32 username, uint256 amount) internal {
        if (_balances[username] == 0) {
            _balances[username] = amount;
        }
        else {_balances[username] += amount;}
    }

    function _getValue(bytes32 username) internal view returns (uint256) {
        return _balances[username];
    }

    function _getInvestorOpen() public view returns (bool) {
        return isInvestorOpen;
    }

    function _getParticipantOpen() public view returns (bool) {
        return isParticipantOpen;
    }

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