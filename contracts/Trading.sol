// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {IERC20} from "./IERC20.sol";
import {Token} from "./Token.sol";

contract Trading {
    event TradeStatusChange(uint256 ad, bytes32 status);

    struct Trade {
        address poster;
        uint256 amount;
        uint256 price;
        bytes32 token;
        bytes32 status; // Open, Executed, Cancelled
    }

    mapping(uint256 => Trade) public trades;

    uint256 tradeCounter = 0;

    IERC20 private _currency;
    address owner;

    constructor(address currency) {
        _currency = IERC20(currency);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function resetTrades() public onlyOwner {
        for (uint256 i = 0; i < tradeCounter; i++) {
            Trade storage trade = trades[i];
            trade.poster = address(0);
            trade.token = "";
            trade.amount = 0;
            trade.price = 0;
            trade.status = "";
        }
        tradeCounter = 0;
    }

    /**
     * @dev Opens a new trade. 
     * @param _amount Maximum of the number of tokens being sold
     * @param _price The price for each token.
     */
    function openTrade(address sender, bytes32 _token, uint256 _amount, uint256 _price)
        public onlyOwner
    {
        // don't transfer right away, as that interferes with the loan computations
        // simply need to ensure that things don't get overwritten/dangered when writing
        trades[tradeCounter] = Trade({
            poster: sender,
            token: _token,
            amount: _amount,
            price: _price,
            status: "Open"
        });
        tradeCounter += 1;
        emit TradeStatusChange(tradeCounter - 1, "Open");
    }

    /**
     * @dev Executes a trade. Must have approved this contract to transfer the
     * amount of currency specified to the poster. Transfers ownership of the
     * item to the filler.
     * @param _amount The amount of tokens to buy at that price
     * @param _trade The id of an existing trade
     */
    function executeTrade(bytes32 token, uint256 _amount, uint256 _trade, address sender) public onlyOwner returns (address)
    {
        // need to prompt the buyer to give the spender tokens
        require(_trade < tradeCounter && _trade >= 0, "invalid trade id"); 
        require(_amount > 0, "amount must be positive");
        Trade storage trade = trades[_trade];
        require(token == trade.token, "token not matched");
        require(_amount <= trade.amount, "bid size not matched");
        require(trade.status == "Open", "Trade is not Open.");
        require(sender != trade.poster, "can't sell to yourself");
        require(_currency.balanceOf(sender) > _amount * trade.price, "insufficient balance");
        // assuming allowance has been granted
        _currency.transferFrom(sender, address(this), _amount * trade.price);
        _currency.transfer(trade.poster, _amount * trade.price);
        uint256 excess = _currency.allowance(sender, address(this));
        if (excess > 0) {
           _currency.transferFrom(sender, address(this), excess); 
           _currency.transfer(sender, excess);
        }
        trade.status = "Executed";
        emit TradeStatusChange(_trade, "Executed");
        return trade.poster;
    }

    /**
     * @dev Cancels a trade by the poster.
     * @param _trade The trade to be cancelled.
     */
    function cancelTrade(uint256 _trade, address sender)
        public onlyOwner
    {
        require(_trade < tradeCounter && _trade >= 0, "invalid trade id"); 
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