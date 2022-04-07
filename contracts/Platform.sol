// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Token} from "./Token.sol";

contract Platform {
    uint256 internal totalRisk;
    uint256 public time;
    uint256 public constant duration= 30*24*24*60;
    bool internal canReset = true;
    mapping(bytes32 => uint256) private _balances;


    // platform treasury
    uint256 private treasury = 100000; // to cover excess losses and receive excess gains

    //premiums
    uint256 internal participantPremium = 100; //temporary premium amount
    uint256 internal investorInterest = 80; //interest rate for investor, 80 means 0.08 yield

    //total capital
    uint256 internal totalCapital; //we need to figure out a capital that meets regulation (where do we do this?)
    
    //registration control
    uint256 internal max; //we need some maximum limit where investor/participant are closed off
    bool isInvestorOpen = true;
    bool isParticipantOpen = true;

    //claim amount
    uint256 internal claimAmount = 1000; // temporary

    //platform related id's and addresses
    // bytes32 internal constant platform_id = keccak256("PLATFORM");
    IERC20 internal usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address

    //mappings for investors & participants
    // mapping (address => address) public participantIds;
    // mapping (address => address) public investorIds;
    // mapping (address => uint) public participantSplits; 
    // mapping (address => uint) public investorSplits;
    bytes32 [] internal investorIds;
    mapping(bytes32 => uint256) internal investorRisk; //capital that can be lost (max loss)
    mapping(bytes32 => bool) internal investorExists; // prevent repeats
    bytes32 [] internal participantIds;
    mapping (bytes32 => bool) internal hasClaimed; //whether participant has claim
    mapping (bytes32 => bool) internal participantExists; //prevent repeats
    mapping (bytes32 => address) internal addresses; //for sending usdt at end

    //Token
    Token internal token = new Token("sampleToken");
    uint256 internal stoploss = 50; // stoploss ratio, 50 means .05

    // how to keep track of tokens, have mapping from string name to the token itself?
    // especially needed with 2+ tokens and for use by trading.sol

    //initiate accounts for investors and participants, both internal and token balance
    function _initiateValue(bytes32 username, uint256 amount, bool positive, bool investor, address sender) internal {
        require(addresses[username] == address(0) || addresses[username] == sender);
        if (investor && !investorExists[username]) {
            investorIds.push(username);
            investorExists[username] = true;
        }
        if (investor) {
            if (amount > 0) {
                uint256 risk = stoploss * amount / 1000;
                uint256 tokens = amount / token._getAmountPerStake();
                amount -= risk;
                require(positive || token.balanceOf(sender) - tokens >= 0, "can't have negative token balance");
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
            require(!participantExists[username]);
            participantIds.push(username);
            participantExists[username] = true;
            amount = 0;
            // preferably add or subtract from balance, but this would require having sufficient value
            // assuming so...
            // amount = amount * interest / 1000;
            // if not, in participants.sol require an allowance of the premium calculation times interest
        }
        addresses[username] = sender;
        _updateValue(username, amount, positive);
    }

    // update internal balance
    function _updateValue(bytes32 username, uint256 amount, bool positive) internal {
        if (positive) {
            if (participantExists[username] && amount != 0) {
                require(!hasClaimed[username]);
                hasClaimed[username] = true;
            }
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

    // called by the trading platform
    function _changeReset(bool val) internal {
        canReset = val;
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
            if (value > 0) {
                usdt.transfer(addresses[investorIds[i]], value);
            }
            _balances[investorIds[i]] = 0;
            address investor = addresses[investorIds[i]];
            uint256 tokenBalance = token.balanceOf(investor);
            _burn(investor, tokenBalance);
            addresses[investorIds[i]] = address(0);
            investorExists[investorIds[i]] = false;
            investorRisk[investorIds[i]] = 0;
        }
        delete investorIds;

        for (uint256 i = 0; i < participantIds.length; i++) {
            if (hasClaimed[participantIds[i]]) {
                usdt.transfer(addresses[participantIds[i]], Platform.claimAmount);
            }
            _balances[participantIds[i]] = 0;
            addresses[participantIds[i]] = address(0);
            participantExists[participantIds[i]] = false;
            hasClaimed[participantIds[i]] = false;
        }
        delete participantIds;

        isInvestorOpen = true;
        isParticipantOpen = true;
    }

    function _getTime() public returns (uint256) {
        bool expired = (block.timestamp - time) >= duration;
        if(expired && canReset) {
            time = 0;
            _resetTimeCycle();
        } 
        return block.timestamp - time;
    }

    function _updateCapital() public {
        //if a new investor joins update totalCapital
        //goes through each investor and updates the capital
    }

    function _mint(address addr, uint256 amount) internal {
        token._mint(addr, amount);
    }

    function _burn(address addr, uint256 amount) internal {
        token._burn(addr, amount);
    }

    function _changeTreasury(uint256 amount, bool positive) internal {
        if (!positive) {
            require(treasury - amount >= 0, "Platform out of money");
            treasury -= amount;
        } else{
            treasury += amount;
        }
    }

    //think we should keep this in the investors
    function _payPremium() private {
        // do the calculations
        uint256 excess = participantIds.length * participantPremium - investorIds.length * investorInterest;
        for (uint256 i = 0; i < investorIds.length; i++) { 
            // if the premium amount is constant regardless of losses
            uint256 investorPremium = investorInterest * token.balanceOf(addresses[investorIds[i]]);
            _updateValue(investorIds[i], investorPremium, true);
        }
        require(excess >= 0);
        if (excess > 0) {
            _changeTreasury(excess, true);
        }
    }

}
