pragma solidity >=0.8.11;
import {IERC20} from "../interfaces/IERC20.sol";
import {Token} from "./Token.sol";

contract Platform {
    uint256 totalCapital;
    uint256 time;
    bool isInvestorOpen;
    bool isParticipantOpen;
    uint256 duration = 30*24*24*60; // duration is month

    bytes32 internal constant platform_id = keccak256("PLATFORM");
    IERC20 internal usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address

    mapping(bytes32 => uint256) private _balances;

    // mapping (address => address) public participantIds;
    // mapping (address => address) public investorIds; 
    // mapping (address => uint) public participantSplits;
    // mapping (address => uint) public investorSplits;
    mapping (bytes32 => address) addresses;
    bytes32 [] internal investorIds;
    mapping(bytes32 => bool) internal investorExists;
    bytes32 [] internal participantIds;
    mapping(bytes32 => bool) internal participantExists;

    Token internal token = new Token("sampleToken");

    function _initiateValue(bytes32 username, uint256 amount, bool positive, bool investor, address sender) internal {
        if (investor && !investorExists[username]) {
            investorExists[username] = true;
            investorIds.push(username);
        }
        if (!investor && !participantExists[username]) {
            participantExists[username] = true;
            participantIds.push(username);
        }
        addresses[username] = sender;
        _updateValue(username, amount, positive);
    }

    function _updateValue(username, amount, positive) internal {
        if (positive) {
            _balances[username] += amount;
        }
        else{
            _balances[username] -= amount;
        }
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
        isInvestorOpen = false;
        isParticipantOpen = false;
        time = block.timestamp;
    }

    function _resetTimeCycle() private {
        // first do the premium allocation to investors
        // then return things and reset
        for (uint256 i = 0; i < investorIds.length; i++) {
            uint256 value = _getValue(investorIds[i]);
            require(value >= 0);
            usdt.transfer(addresses[investorIds[i]], value);
            _balances[investorIds[i]] = 0;
            addresses[investorIds[i]] = address(0);
            investorExists[investorIds[i]] = false;
        }
        delete investorIds;
        for (uint256 i = 0; i < participantIds.length; i++) {
            uint256 value = _getValue(participantIds[i]);
            require(value >= 0);
            usdt.transfer(addresses[participantIds[i]], value);
            _balances[participantIds] = 0;
            addresses[participantIds[i]] = address(0);
            participantExists[participantIds[i]] = false;
        }
        delete participantIds;

        time = 0;
        isInvestorOpen = true;
        isParticipantOpen = true;
    }

    function _getTime() public returns (uint256) {
        bool expired = (block.timestamp - time) >= duration;
        if(expired) {
            _resetTimeCycle();
        } 
        return time;
    }

    function _updateCapital() public {
        //if a new investor joins update totalCapital
        //goes through each investor and updates the capital
    }

    function _mint(address addr, uint256 amount) internal {
        token._mint(addr, amount);
    }

    function _burn(address addr, uint256 amount) public {
        token._burn(addr, amount);
    }
}