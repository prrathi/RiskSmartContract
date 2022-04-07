// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InvestorFactory} from "./InvestorFactory.sol";
import {Platform} from "./Platform.sol";

// ADAPTED FROM https://github.com/HQ20/contracts/blob/master/contracts/classifieds/Classifieds.sol

contract Market is InvestorFactory {
    event TradeStatusChange(uint256 ad, bytes32 status);

    IERC20 currencyToken = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
    IERC20 itemToken;

    struct Trade {
        address poster;
        uint256 amount;
        uint256 price;
        bytes32 status; // Open, Executed, Cancelled
    }

    mapping(uint256 => Trade) public trades;

    uint256 tradeCounter;

    constructor (address _itemTokenAddress) 
    {
        itemToken = IERC20(_itemTokenAddress);
        tradeCounter = 0;
    }

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
        if (Platform.time == 0) {
            resetTrades();
        } else{
            require(itemToken.balanceOf(msg.sender) >= _amount);
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
        Platform._changeReset(false);
        require(_trade < tradeCounter && _trade >= 0); 
        require(_amount > 0);
        Trade storage trade = trades[_trade];
        if (_amount > trade.amount) {
            _amount = trade.amount;
        }
        require(trade.status == "Open", "Trade is not Open.");

        // assuming allowance has been granted
        currencyToken.transferFrom(msg.sender, trade.poster, _amount * trade.price);
        InvestorFactory.changeStake(msg.sender, _amount, trade.poster, hashUsername);
        trade.status = "Executed";
        emit TradeStatusChange(_trade, "Executed");
        Platform._changeReset(true);
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