// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {IERC20} from "./IERC20.sol";
import {Token} from "./Token.sol";
import {Trading} from "./Trading.sol";

contract NewPlatform {
    uint256 public time;
    uint256 public constant duration= 30*24*24*60;
    mapping(bytes32 => uint256) private _balances;

    //risk, premiums, and interest
    uint256 private totalRisk;
    uint256 private participantPremium; // = 100; //temporary premium amount
    uint256 private totalInterest;
    // uint256 private investorInterest;// = 80; //interest rate for investor, 80 means 0.08 yield

    //total capital
    uint256 private totalCapital; //we need to figure out a capital that meets regulation (where do we do this?)
    
    //registration control
    uint256 private max; //we need some maximum limit where investor/participant are closed off
    bool public isInvestorOpen = false;
    bool public isParticipantOpen = true;

    //claim amount
    uint256 private claimAmount; // temporary

    //money and trading
    IERC20 private _currency; // = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address
    mapping(bytes32 => address) tokens;
    bytes32 [] private tokensArray;
    Trading private trading;

    bytes32 [] private investorIds;
    mapping(bytes32 => uint256) private investorRisk; //capital that can be lost (max loss)
    mapping(bytes32 => bool) private investorExists; // prevent repeats
    bytes32 [] private participantIds;
    mapping (bytes32 => bool) private hasClaimed; //whether participant has claim
    mapping (bytes32 => bool) private participantExists; //prevent repeats
    mapping (bytes32 => address) private addresses; //for sending usdt at end

    address private owner;
    address public fake;
    // how to keep track of tokens, have mapping from string name to the token itself?
    // especially needed with 2+ tokens and for use by trading.sol
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier duringSession() {
        require(time > 0, "no current session");
        require(!_resetTime());
        _;
    }

    constructor(address currency, uint256 _premium, uint256 _loss) {
        // fake = currency;
        _currency = IERC20(currency);
        trading = new Trading(currency);
        owner = msg.sender;
        participantPremium = _premium;
        claimAmount = _loss;
    } 

    function tradingAddress() public view returns (address) {
        return address(trading);
    }

    function addToken(bytes32 tokenName, uint256 investorInterest, uint256 stopLoss) public onlyOwner {
        Token token = new Token(tokenName, investorInterest, stopLoss);
        tokens[tokenName] = address(token);
        tokensArray.push(tokenName);
    }

    //initiate accounts for investors and participants, both private and token balance
    function _initiateValue(bytes32 token, bytes32 username, uint256 amount, bool positive, bool investor, address sender) private {
        if (addresses[username] == address(0)){
            addresses[username] = sender;
        } else{
            require(addresses[username] == sender, "invalid username");
        }
        if (investor && !investorExists[username]) {
            investorIds.push(username);
            investorExists[username] = true;
        }
        Token currToken = Token(tokens[token]);
        if (investor) {
            if (amount > 0) {
                uint256 risk = currToken.stopLoss() * amount / 1000;
                uint256 stake = amount / currToken._getAmountPerStake();
                amount -= risk;
                require(positive || currToken.balanceOf(sender) - stake >= 0, "can't have negative token balance");
                if (positive) {
                    totalRisk += risk;
                    investorRisk[username] += risk;
                    _mint(token, sender, stake);
                }
                else {
                    totalRisk -= risk;
                    investorRisk[username] -= risk;
                    _burn(token, sender, stake);
                }
            }
        } else {
            require(!participantExists[username]);
            participantIds.push(username);
            participantExists[username] = true;
            amount = 0;
        }
        if (amount != 0) {
            if (positive) {
                _balances[username] += amount;
            }
            else{
                _balances[username] -= amount;
            }
        }
    }

    function splitClaim(bytes32 hashUsername) private {
        // splitting mechanism for now
        // fix floating point stuff later
        if (totalRisk > claimAmount) {
           for (uint i = 0; i < investorIds.length; i++) {
               uint256 val = investorRisk[investorIds[i]];
               if (val > 0) {
                  investorRisk[investorIds[i]] -= val * claimAmount / totalRisk; 
               }
           }
           totalRisk -= claimAmount;
        } else {
           for (uint i = 0; i < investorIds.length; i++) {
               uint256 val = investorRisk[investorIds[i]];
               if (val > 0) {
                  investorRisk[investorIds[i]] = 0; 
               }
           } 
        }
    }

    function _startTimeCycle() public onlyOwner {
        require(time == 0); //for month cycle
        require(isInvestorOpen);
        isInvestorOpen = false;
        time = block.timestamp;
    }

    function _resetTimeCycle() public onlyOwner { 
        // this would eventually be changed to private so owner can't game the system

        // first do the premium allocation to investors
        // then return things and reset
        _payPremium();

        for (uint256 i = 0; i < participantIds.length; i++) {
            if (hasClaimed[participantIds[i]]) {
                splitClaim(participantIds[i]);
                _currency.transfer(addresses[participantIds[i]], claimAmount);
            }
            _balances[participantIds[i]] = 0;
            addresses[participantIds[i]] = address(0);
            participantExists[participantIds[i]] = false;
            hasClaimed[participantIds[i]] = false;
        }
        delete participantIds;

        for (uint256 i = 0; i < investorIds.length; i++) {
            uint256 value = _balances[investorIds[i]];
            require(value >= 0, "capital negative value");
            uint256 value2 = investorRisk[investorIds[i]];
            require(value2 >= 0, "risk money negative value");
            value += value2;            
            if (value > 0) {
                _currency.transfer(addresses[investorIds[i]], value);
            }
            _balances[investorIds[i]] = 0;
            address investor = addresses[investorIds[i]];

            for (uint256 j = 0; j < tokensArray.length; j++) {
                uint256 tokenBalance = Token(tokens[tokensArray[j]]).balanceOf(investor);
                _burn(tokensArray[j], investor, tokenBalance);
            }
            addresses[investorIds[i]] = address(0);
            investorExists[investorIds[i]] = false;
            investorRisk[investorIds[i]] = 0;
        }
        delete investorIds;

        trading.resetTrades();

        totalInterest = 0;
        totalRisk = 0;
        isParticipantOpen = true;
    }

    function _resetTime() private returns (bool) {
        bool expired = (block.timestamp - time) >= duration;
        if(expired) {
            time = 0;
            _resetTimeCycle();
        } 
        return expired;
    }

    function _getTime() public returns (uint256) {
        _resetTime();
        return block.timestamp - time;
    }

    function _mint(bytes32 token, address addr, uint256 amount) private {
        Token currToken = Token(tokens[token]);
        currToken._mint(addr, amount);
    }

    function _burn(bytes32 token, address addr, uint256 amount) private {
        Token currToken = Token(tokens[token]);
        currToken._burn(addr, amount);
    }

    function _payPremium() private {
        // do the calculations
        uint256 excess = participantIds.length * participantPremium - totalInterest;
        require(excess >= 0);
        for (uint256 j = 0; j < tokensArray.length; j++) {
            Token temp = Token(tokens[tokensArray[j]]);
            uint256 scale = temp.investorInterest() * temp._getAmountPerStake() / 1000;
            for (uint256 i = 0; i < investorIds.length; i++) { 
                uint256 investorPremium = scale * temp.balanceOf(addresses[investorIds[i]]);
                if (investorPremium != 0) {
                    _balances[investorIds[i]] += investorPremium;
                }
            }
        }
    }

    function participantClose() public onlyOwner {
        require(isParticipantOpen);
        isParticipantOpen = false;
        // at this point oracle would be called to get data
        isInvestorOpen = true;
    }
    
    //address
    mapping (address => bytes32) public participantAddressToId;
    // mapping (bytes32 => address) idToAddress; //from platform to Participant

    event newParticipant(bytes32 hashUsername);

    function createParticipant(bytes32 hashUsername) public {
        // return _currency.allowance(msg.sender, address(this));
        require(isParticipantOpen, "currently closed");
        require(participantAddressToId[msg.sender] == 0, "address used");
        require(!(investorExists[hashUsername] || participantExists[hashUsername]), "username taken");
        participantAddressToId[msg.sender] = hashUsername;
        // _currency.approve(address(this), premium); //GET ACTUAL APPROVAL MECHANISM
        _currency.transferFrom(msg.sender, address(this), participantPremium);
        // participantAddresses[hashUsername] = Participant(0, 0);
        _initiateValue(0, hashUsername, 0, false, false, msg.sender); 
        emit newParticipant(hashUsername);
    }

    //mapping for values which can all be accessible from the admin.Platform()
    // mapping (address => uint) public mapCoverageSize;
    // mapping (address => uint) public mapTotalClaims;
    // mapping (address => uint) public mapPremium;
    // mapping (address => uint) public mapProfit;
    // mapping (address => bool) public mapOpen;

    //register the claim
    function registerClaim(bytes32 hashUsername) public duringSession {
        require(hashUsername == participantAddressToId[msg.sender], "invalid user");
        require(!hasClaimed[hashUsername], "claim already filed");
        hasClaimed[hashUsername] = true;
    }

    mapping (address => bytes32) investorAddressToId; //address to id for platform

    event changeInvestor(bytes32 token, bytes32 _hashUsername, uint256 tokens, bool sign); // add type of token in future

    function createInvestor(bytes32 token, uint256 _capital, bytes32 hashUsername) public {
        // some indicator or capping factor would set finished to true
        require(isInvestorOpen, "currently closed");
        require(tokens[token] != address(0), "token not valid");
        if (investorAddressToId[msg.sender] == 0) {
            require(!(investorExists[hashUsername] || participantExists[hashUsername]), "username taken");
            investorAddressToId[msg.sender] = hashUsername;
        }
        else {
            require(investorAddressToId[msg.sender] == hashUsername, "wrong username"); 
        }
        uint256 numStake = _capital/Token(tokens[token])._getAmountPerStake();
        uint256 capital = numStake * Token(tokens[token])._getAmountPerStake();
        uint tmp = Token(tokens[token]).investorInterest() * capital / 1000);
        require((totalInterest + tmp) < (participantPremium * participantIds.length), "not enough participants in pool");
        // usdt.approve(address(this), _capital); //GET ACTUAL APPROVAL MECHANISM
        _currency.transferFrom(msg.sender, address(this), _capital);
        if (_capital > capital) {
            _currency.transfer(msg.sender, (_capital - capital));
        }
        totalInterest += Token(tokens[token]).investorInterest() * capital / 1000;
        _initiateValue(token, hashUsername, capital, true, true, msg.sender);
        emit changeInvestor(token, hashUsername, numStake, true);
    }

    function changeStake(bytes32 token, address receiver, uint256 stake, address partner, bytes32 hashUsername) private {
        require(stake != 0);
        require(investorAddressToId[partner] != 0);
        require(Token(tokens[token]).balanceOf(receiver) + stake >= 0);
        require(Token(tokens[token]).balanceOf(partner) - stake >= 0);
        
        if (investorAddressToId[receiver] == 0) {
            require(!(investorExists[hashUsername] || participantExists[hashUsername]), "username taken");
            investorAddressToId[receiver] = hashUsername;
        } else {
            require(hashUsername == investorAddressToId[receiver]);
        }
        // burn one person's and mint another person's
        _initiateValue(token, investorAddressToId[partner], stake*Token(tokens[token])._getAmountPerStake(), false, true, partner);
        _initiateValue(token, investorAddressToId[receiver], stake*Token(tokens[token])._getAmountPerStake(), true, true, receiver);
        emit changeInvestor(token, hashUsername, stake, true);
        emit changeInvestor(token, investorAddressToId[partner], stake, false);
    }

    function getValue() public view returns (uint256) {
        require(investorAddressToId[msg.sender] != 0, "must have an account");
        bytes32 hashedUsername = investorAddressToId[msg.sender];
        return _balances[hashedUsername];
    } 

    function openTrade(bytes32 token, uint256 amount, uint256 price) public duringSession returns (uint256) {
        require(Token(tokens[token]).balanceOf(msg.sender) >= amount, "requested sell size larger than stake size");
        trading.openTrade(msg.sender, token, amount, price);
    }

    function executeTrade(bytes32 token, uint256 amount, uint256 trade, bytes32 hashUsername) public duringSession {
        // requires allowance of amount * trading price from msg.sender to trading address
        address poster = trading.executeTrade(token, amount, trade, msg.sender);
        changeStake(token, msg.sender, amount, poster, hashUsername);
    }

    function cancelTrade(uint256 trade) public duringSession {
        trading.cancelTrade(trade, msg.sender);
    }
}
