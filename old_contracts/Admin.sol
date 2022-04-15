// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Platform} from "./Platform.sol";
import {InvestorFactory} from "./InvestorFactory.sol";
import {ParticipantFactory} from "./ParticipantFactory.sol";
import {Trading} from "./Trading.sol";
import {Token} from "./Token.sol";

contract Admin {
    Platform internal _platform;
    InvestorFactory internal _investorFactory;
    ParticipantFactory internal _participantFactory;
    Trading internal _trading;
    // later make an array of tokens
    Token internal token;

    address internal _treasury;
    IERC20 internal _currency = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // mainnet USDT contract address

    constructor(address treasury) {
        _treasury = treasury;
        token = Token("sampleToken");
    }

    function initializePlatform(Platform platform_) public initializer {
        _platform = platform_;
    }

    function initializeInvestor(InvestorFactory investor) public initializer {
        _investorFactory = investor;
    }

    function initializeParticipant(ParticipantFactory participant) public initializer {
        _participantFactory = participant;
    }

    function initializeTrading(Trading trader) public initializer {
        _trading = trader;
    }

    function Platform() public returns (Platform) {
        return _platform;
    }

    function InvestorFactory() public returns (InvestorFactory) {
        return _investorFactory;
    }

    function ParticipantFactory() public returns (ParticipantFactory) {
        return _participantFactory;
    }

    function Trading() public returns (Trading) {
        return _trading;
    }

    function Token() public returns (Token) {
        return token;
    }

    function Currency() public returns (IERC20) {
        return _currency;
    }
}