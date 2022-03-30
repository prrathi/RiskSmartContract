pragma solidity >=0.8.11;
import {IERC20} from "../interfaces/IERC20.sol";
import {Token} from "./Token.sol";

contract Platform {
    uint256 internal totalRisk;
    uint256 public time;
    bool public isInvestorOpen;
    bool public isParticipantOpen;
    uint256 public constant duration = 30*24*24*60; // duration is month
    // uint256 public constant interest = 10; // temporary interest for that period, means 100/1000
    uint256 internal constant premium = 100; // temporary premium amount
    uint256 internal constant stoploss = 100; // temporary stop loss ratio, means 100/1000

    bytes32 internal constant platform_id = keccak256("PLATFORM");
    IERC20 internal usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address

    mapping(bytes32 => uint256) private _balances;

    // mapping (address => address) public participantIds;
    // mapping (address => address) public investorIds; 
    // mapping (address => uint) public participantSplits;
    // mapping (address => uint) public investorSplits;
    mapping (bytes32 => address) addresses;
    bytes32 [] internal investorIds;
    mapping(bytes32 => uint256) internal investorRisk;
    bytes32 [] internal participantIds;
    mapping(bytes32 => uint256) internal participantValue;

    Token internal token = new Token("sampleToken");

    function _initiateValue(bytes32 username, uint256 amount, bool positive, bool investor, address sender) internal {
        if (investor && addresses[username] == address(0)) {
            investorIds.push(username);
        }
        if (investor) {
            if (amount > 0) {
                uint256 risk = stoploss * amount / 1000;
                uint256 tokens = amount / token._amountPerStake;
                require(positive || token.balanceOf(sender) - amount >= 0, "can't have negative token balance");
                if (positive) {
                    totalRisk += risk;
                    investorRisk[username] += risk;
                    _mint(sender, tokens);
                }
                else {
                    totalRisk -= risk;
                    investorRisk[username] -= risk;
                    _burn(sender, tokens);
                }
            }
        } else {
            participantExists[username] = amount;
            participantIds.push(username);
            amount = 0;
            // preferably add or subtract from balance, but this would require having sufficient value
            // assuming so...
            // amount = amount * interest / 1000;
            // if not, in participants.sol require an allowance of the premium calculation times interest
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
        _payPremium();
        for (uint256 i = 0; i < investorIds.length; i++) {
            uint256 value = _getValue(investorIds[i]);
            require(value >= 0);
            usdt.transfer(addresses[investorIds[i]], value);
            _balances[investorIds[i]] = 0;
            investorExists[investorIds[i]] = false;

            address investor = addresses[investorIds[i]];
            uint256 balance = token.balanceOf(investor);
            _burn(investor, balance);
            addresses[investorIds[i]] = address(0);
        }
        delete investorIds;
        for (uint256 i = 0; i < participantIds.length; i++) {
            uint256 value = _getValue(participantIds[i]);
            require(value >= 0);
            usdt.transfer(addresses[participantIds[i]], value);
            _balances[participantIds] = 0;
            addresses[participantIds[i]] = address(0);
            participantValue[participantIds[i]] = 0;
        }
        delete participantIds;

        time = 0;
        isInvestorOpen = true;
        isParticipantOpen = true;
    }

    function _payPremium() private {
        // do the calculations
        uint256 totalPremium = premium*participantIds.length;
        for (uint256 i = 0; i < investorIds.length; i++) { 
            uint256 investorPremium = totalPremium * _getValue(investorIds[i]) / totalRisk;
            _updateValue(investorIds[i], investorPremium, true);
        }
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