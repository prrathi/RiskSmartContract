// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {IERC20} from "./IERC20.sol";
import {Token} from "./Token.sol";

contract NewPlatform {
    uint256 private totalRisk;
    uint256 public time;
    uint256 public constant duration= 30*24*24*60;
    bool private canReset = true;
    mapping(bytes32 => uint256) private _balances;

    //premiums
    uint256 private participantPremium; // = 100; //temporary premium amount
    uint256 private investorInterest;// = 80; //interest rate for investor, 80 means 0.08 yield

    //total capital
    uint256 private totalCapital; //we need to figure out a capital that meets regulation (where do we do this?)
    
    //registration control
    uint256 private max; //we need some maximum limit where investor/participant are closed off
    bool public isInvestorOpen = true;
    bool public isParticipantOpen = true;

    //claim amount
    uint256 private claimAmount; // temporary

    //money
    IERC20 private _currency; // = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address
    Token private token;

    //platform related id's and addresses
    // bytes32 private constant platform_id = keccak256("PLATFORM");

    //mappings for investors & participants
    // mapping (address => address) public participantIds;
    // mapping (address => address) public investorIds;
    // mapping (address => uint) public participantSplits; 
    // mapping (address => uint) public investorSplits;
    bytes32 [] private investorIds;
    mapping(bytes32 => uint256) private investorRisk; //capital that can be lost (max loss)
    mapping(bytes32 => bool) private investorExists; // prevent repeats
    bytes32 [] private participantIds;
    mapping (bytes32 => bool) private hasClaimed; //whether participant has claim
    mapping (bytes32 => bool) private participantExists; //prevent repeats
    mapping (bytes32 => address) private addresses; //for sending usdt at end

    uint256 private stoploss = 50; // stoploss ratio, 50 means .05
    bool private call = true;

    address private owner;
    address public fake;
    // how to keep track of tokens, have mapping from string name to the token itself?
    // especially needed with 2+ tokens and for use by trading.sol
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(/*address currency,*/ uint256 _premium, uint256 _interest, uint256 _loss) {
        // fake = currency;
        // _currency = IERC20(currency);
        owner = msg.sender;
        participantPremium = _premium;
        investorInterest = _interest;
        claimAmount = _loss;
    } 

    function initialize(address currency, bytes32 tok) public onlyOwner {
        require(call, "not callable");
        _currency = IERC20(currency);
        token = new Token(tok);
        call = false;
    }

    function play(bytes32 username) public view returns (uint256) {
        return investorRisk[username];
    }
    function play2(bytes32 username) public view returns (uint256) {
        return _balances[username];
    }

    function checkExists(bytes32 username) public view returns (bool){
        return (investorExists[username] || participantExists[username]);
    }
    //initiate accounts for investors and participants, both private and token balance
    function _initiateValue(bytes32 username, uint256 amount, bool positive, bool investor, address sender) private {
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
        }
        addresses[username] = sender;
        _updateValue(username, amount, positive);
    }

    // update private balance
    function _updateValue(bytes32 username, uint256 amount, bool positive) private {
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
        hasClaimed[hashUsername] = true;

        uint256 outstandingClaim = claimAmount;
        uint256 unitClaim = claimAmount/token.totalSupply(); // how much each person has to pay -> won't be actual calculation
        uint256 remainingCapital = 0;
        for (uint i = 0; i < investorIds.length; i++) {
            bytes32 investorId = investorIds[i];
            if (investorRisk[investorId] >= unitClaim*token.balanceOf(addresses[investorIds[i]])) {
                investorRisk[investorId] -= unitClaim*token.balanceOf(addresses[investorIds[i]]);
                outstandingClaim -= unitClaim*token.balanceOf(addresses[investorIds[i]]);
                remainingCapital += investorRisk[investorId];
            } else{
                if (investorRisk[investorId] > 0) {
                    investorRisk[investorId] = 0;
                    outstandingClaim -= investorRisk[investorId];
                }
            }
        }
        if (remainingCapital <= outstandingClaim) {
            for (uint i = 0; i < investorIds.length; i++) {
                investorRisk[investorIds[i]] = 0;
            }
            // _changeTreasury(outstandingClaim - remainingCapital, false);
        } else{
            for (uint i = 0; i < investorIds.length; i++) {
                investorRisk[investorIds[i]] = investorRisk[investorIds[i]] * (remainingCapital - outstandingClaim) / remainingCapital;
            }
        }
        // _updateValue(hashUsername, claimAmount, true); // not needed
    }

    // called by the trading platform
    function _changeReset(bool val) private {
        canReset = val;
    }

    function _startTimeCycle() public onlyOwner {
        require(time == 0); //for month cycle
        isInvestorOpen = false;
        isParticipantOpen = false;
        time = block.timestamp;
    }

    function _resetTimeCycle() public onlyOwner {
        // first do the premium allocation to investors
        // then return things and reset
        _payPremium();
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
            uint256 tokenBalance = token.balanceOf(investor);
            _burn(investor, tokenBalance);
            addresses[investorIds[i]] = address(0);
            investorExists[investorIds[i]] = false;
            investorRisk[investorIds[i]] = 0;
        }
        delete investorIds;

        for (uint256 i = 0; i < participantIds.length; i++) {
            if (hasClaimed[participantIds[i]]) {
                _currency.transfer(addresses[participantIds[i]], claimAmount);
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

    function _updateCapital() private {
        //if a new investor joins update totalCapital
        //goes through each investor and updates the capital
    }

    function _mint(address addr, uint256 amount) private {
        token._mint(addr, amount);
    }

    function _burn(address addr, uint256 amount) private {
        token._burn(addr, amount);
    }

    // function _changeTreasury(uint256 amount, bool positive) private {
        // if (!positive) {
            // require(treasury - amount >= 0, "Platform out of money");
            // treasury -= amount;
        // } else{
            // treasury += amount;
        // }
    // }

    //think we should keep this in the investors
    function _payPremium() private {
        // do the calculations
        uint256 excess = participantIds.length * participantPremium - investorIds.length * investorInterest;
        for (uint256 i = 0; i < investorIds.length; i++) { 
            // if the premium amount is constant regardless of losses
            uint256 investorPremium = investorInterest * token._getAmountPerStake() * token.balanceOf(addresses[investorIds[i]]) / 1000;
            _updateValue(investorIds[i], investorPremium, true);
        }
        require(excess >= 0);
        // if (excess > 0) {
            // _changeTreasury(excess, true);
        // }
    }

    // struct Payments {
        // address investorAddress;
        // uint256 paymentToInvestor;
        // //Claim if we make contract for claims
    // }

    //all participants on platform
    // Participant[] public participants;
    // Payments[] public payments;
    // bytes32[] public particpantsIds;
    // mapping (bytes32 => Participant) idToParticipant;
    // address[] public participantAddresses;
    
    //address
    mapping (address => bytes32) public participantAddressToId;
    // mapping (bytes32 => address) idToAddress; //from platform to Participant

    event newParticipant(bytes32 hashUsername);

    function createParticipant(bytes32 hashUsername) public {
        // return _currency.allowance(msg.sender, address(this));
        require(isParticipantOpen, "currently closed");
        require(participantAddressToId[msg.sender] == 0, "address used");
        require(!checkExists(hashUsername), "username taken");
        participantAddressToId[msg.sender] = hashUsername;
        // _currency.approve(address(this), premium); //GET ACTUAL APPROVAL MECHANISM
        _currency.transferFrom(msg.sender, address(this), 100);
        // participantAddresses[hashUsername] = Participant(0, 0);
        _initiateValue(hashUsername, 0, false, false, msg.sender); 
        emit newParticipant(hashUsername);
    }

    //mapping for values which can all be accessible from the admin.Platform()
    // mapping (address => uint) public mapCoverageSize;
    // mapping (address => uint) public mapTotalClaims;
    // mapping (address => uint) public mapPremium;
    // mapping (address => uint) public mapProfit;
    // mapping (address => bool) public mapOpen;

    //register the claim
    function registerClaim(bytes32 hashUsername) public {
        require(hashUsername == participantAddressToId[msg.sender], "invalid user");
        require(!hasClaimed[hashUsername], "claim already filed");
        splitClaim(hashUsername);
        // if there is a claim username we would want to push that into claims array
    }

    mapping (address => bytes32) investorAddressToId; //address to id for platform

    event changeInvestor(bytes32 _hashUsername, uint256 tokens); // add type of token in future

    function createInvestor(uint256 _capital, bytes32 hashUsername) public {
        // some indicator or capping factor would set finished to true
        require(isInvestorOpen, "currently closed");
        require(investorAddressToId[msg.sender] == 0, "address used"); //each account is associated with address 
        require(!checkExists(hashUsername), "username taken");

        investorAddressToId[msg.sender] = hashUsername;
        uint256 numStake = _capital/token._getAmountPerStake();
        uint256 capital = numStake * token._getAmountPerStake();
        // usdt.approve(address(this), _capital); //GET ACTUAL APPROVAL MECHANISM
        _currency.transferFrom(msg.sender, address(this), _capital);
        _currency.transfer(msg.sender, (_capital - capital));
        _initiateValue(hashUsername, capital, true, true, msg.sender);
        emit changeInvestor(hashUsername, numStake);
    }

    function changeStake(address receiver, uint256 stake, address partner, bytes32 hashUsername) private {
        // under current implementation if there was someone new, they would have to be the one to call this
        require(stake != 0);
        require(investorAddressToId[partner] != 0);
        uint256 senderBalance = token.balanceOf(receiver);
        uint256 partnerBalance = token.balanceOf(partner);
        require(senderBalance + stake >= 0);
        require(partnerBalance - stake >= 0);
        
        if (investorAddressToId[receiver] == 0) {
            // require(hashUsername != admin.Platform()_id, "Username taken");
            require(!checkExists(hashUsername), "Username taken");
            investorAddressToId[receiver] = hashUsername;
            _initiateValue(hashUsername, 0, true, true, msg.sender);
        } else {
            require(hashUsername == investorAddressToId[msg.sender]);
        }

        // require(token.allowance(partner, receiver) >= stake);
        // not sure how the actual transfer works
        // do we facilitate the creation of allowance and then transfer?

        // alternate method: burn one person's and mint another person's
        _burn(partner, stake);
        _mint(receiver, stake);
        _initiateValue(investorAddressToId[partner], stake*token._getAmountPerStake(), false, true, partner);
        _initiateValue(investorAddressToId[receiver], stake*token._getAmountPerStake(), true, true, partner);
        emit changeInvestor(hashUsername, stake);
        emit changeInvestor(investorAddressToId[partner], 0 - stake);
    }

    function getValue() public view returns (uint256) {
        require(investorAddressToId[msg.sender] != 0);
        bytes32 hashedUsername = investorAddressToId[msg.sender];
        return _balances[hashedUsername];
    } 

    event TradeStatusChange(uint256 ad, bytes32 status);

    struct Trade {
        address poster;
        uint256 amount;
        uint256 price;
        bytes32 status; // Open, Executed, Cancelled
    }

    mapping(uint256 => Trade) public trades;

    uint256 tradeCounter = 0;

    function resetTrades() private {
        for (uint256 i = 0; i < tradeCounter; i++) {
            Trade storage trade = trades[i];
            trade.poster = address(0);
            trade.amount = 0;
            trade.price = 0;
            trade.status = "";
        }
        tradeCounter = 0;
    }

    /**
     * @dev Returns the details for a trade.
     * @param _trade The id for the trade.
     */
    function getTrade(uint256 _trade)
        public
        view
        returns(address, uint256, uint256, bytes32)
    {
        require(_trade < tradeCounter && _trade >= 0);
        Trade memory trade = trades[_trade];
        return (trade.poster, trade.amount, trade.price, trade.status);
    }

    /**
     * @dev Opens a new trade. 
     * @param _amount Maximum of the number of tokens being sold
     * @param _price The price for each token.
     */
    function openTrade(uint256 _amount, uint256 _price)
        public
    {
        // don't transfer right away, as that interferes with the loan computations
        // simply need to ensure that things don't get overwritten/dangered when writing
        if (time == 0) {
            resetTrades();
        } else{
            require(token.balanceOf(msg.sender) >= _amount);
            trades[tradeCounter] = Trade({
                poster: msg.sender,
                amount: _amount,
                price: _price,
                status: "Open"
            });
            tradeCounter += 1;
            emit TradeStatusChange(tradeCounter - 1, "Open");
        }
    }

    /**
     * @dev Executes a trade. Must have approved this contract to transfer the
     * amount of currency specified to the poster. Transfers ownership of the
     * item to the filler.
     * @param _amount The amount of tokens to buy at that price
     * @param _trade The id of an existing trade
     */
    function executeTrade(uint256 _amount, uint256 _trade, bytes32 hashUsername) public
    {
        // need to prompt the buyer to give the spender tokens
        _changeReset(false);
        require(_trade < tradeCounter && _trade >= 0); 
        require(_amount > 0);
        Trade storage trade = trades[_trade];
        if (_amount > trade.amount) {
            _amount = trade.amount;
        }
        require(trade.status == "Open", "Trade is not Open.");

        // assuming allowance has been granted
        _currency.transferFrom(msg.sender, trade.poster, _amount * trade.price);
        changeStake(msg.sender, _amount, trade.poster, hashUsername);
        trade.status = "Executed";
        emit TradeStatusChange(_trade, "Executed");
        _changeReset(true);
    }

    /**
     * @dev Cancels a trade by the poster.
     * @param _trade The trade to be cancelled.
     */
    function cancelTrade(uint256 _trade)
        public
    {
        Trade storage trade = trades[_trade];
        require(
            msg.sender == trade.poster,
            "Trade can be cancelled only by poster."
        );
        require(trade.status == "Open", "Trade is not Open.");
        // itemToken.transferFrom(address(this), trade.poster, trade.item);
        trade.status = "Cancelled";
        emit TradeStatusChange(_trade, "Cancelled");
    }
}
