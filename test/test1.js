var NewPlatform = artifacts.require("../contracts/NewPlatform.sol");
var TetherToken = artifacts.require("../contracts/Tether.sol")
var Token = artifacts.require("../contracts/Token.sol")
var Trading = artifacts.require("../contracts/Trading.sol")
var assert = require("assert");

// it labels:
// t: # of tokens
// ii: # of initial investors
// fi: # of future investors (by trading)
// p: # of participants
// c: # of claims

contract("NewPlatform", (accounts) => {
  it("1t 2ii 1fi 2p 1c", async () => {
    // account 0 is the owner of platform
    // account 1 is participant who files claim
    // account 2 is participant who doesn't file claim
    // account 3 is investor with 1 stake
    // account 4 is investor with 4 stakes who sells one
    // account 5 is investor who buys 1 stake from account 4

    var keccak256 = require("keccak256");
    var tokenName1 = keccak256("sample");
    var tether = await TetherToken.deployed();
    var platform1 = await NewPlatform.new(tether.address, 100, 200);
    await platform1.addToken(tokenName1, 80, 50);
    // var init = await platform1.initialize(tether.address, tokenName);

    await tether._mint(platform1.address, 1000);
    await tether._mint(accounts[1], 1000);
    await tether._mint(accounts[2], 1000);
    await tether._mint(accounts[3], 1000);
    await tether._mint(accounts[4], 1000);
    await tether._mint(accounts[5], 1000);

    var val;
    console.log("BEFORE PERIOD")
    var val = await tether.balanceOf.call(platform1.address);
    console.log("Platform balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[1]);
    console.log("Participant 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[2]);
    console.log("Participant 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[3]);
    console.log("Investor 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[4]);
    console.log("Investor 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[5]);
    console.log("Future investor balance: " + val["words"][0]);
    console.log("")

    await tether.approve(platform1.address, 100, {from: accounts[1]});
    var participantName1 = keccak256("participant1");
    await platform1.createParticipant(participantName1, {from: accounts[1]});

    await tether.approve(platform1.address, 100, {from: accounts[2]});
    var participantName2 = keccak256("participant2");
    await platform1.createParticipant(participantName2, {from: accounts[2]});

    await platform1.participantClose();

    await tether.approve(platform1.address, 150, {from: accounts[3]});
    var investorName1 = keccak256("investor1");
    await platform1.createInvestor(tokenName1, 150, investorName1, {from: accounts[3]});

    await tether.approve(platform1.address, 400, {from: accounts[4]});
    var investorName2 = keccak256("investor2");
    await platform1.createInvestor(tokenName1, 400, investorName2, {from: accounts[4]});

    console.log("AFTER SIGNUP")
    var val = await tether.balanceOf.call(platform1.address);
    console.log("Platform balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[1]);
    console.log("Participant 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[2]);
    console.log("Participant 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[3]);
    console.log("Investor 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[4]);
    console.log("Investor 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[5]);
    console.log("Future investor balance: " + val["words"][0]);
    console.log("")

    await platform1._startTimeCycle();

    await platform1.registerClaim(participantName1, {from: accounts[1]});

    var tradingAddress = await platform1.tradingAddress.call();
    await platform1.openTrade(tokenName1, 2, 102, {from: accounts[4]});
    var investorName3 = keccak256("investor3");
    await tether.approve(tradingAddress, 103, {from: accounts[5]});
    await platform1.executeTrade(tokenName1, 1, 0, investorName3, {from: accounts[5]});

    await platform1._resetTimeCycle(); 
    
    var val;
    console.log("AFTER PERIOD")
    var val = await tether.balanceOf.call(platform1.address);
    console.log("Platform balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[1]);
    console.log("Participant 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[2]);
    console.log("Participant 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[3]);
    console.log("Investor 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[4]);
    console.log("Investor 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[5]);
    console.log("Future investor balance: " + val["words"][0]);
    console.log("")
  });

  it("2t 2ii 2fi 2p 2c", async () => {
    // account 0 is the owner of platform
    // account 1 is a participant who files claim
    // account 2 is a participant who files claim
    // account 3 is investor with 2 stakes of token1, buys 1 of token1 from account 4
    // account 4 is investor with 1 stake of token1 and 1 of token2
    // account 5 is investor who buys 3 stakes of token1 from account 3

    var keccak256 = require("keccak256");
    var tokenName1 = keccak256("sample1");
    var tokenName2 = keccak256("sample2");
    var tether = await TetherToken.deployed();
    var platform1 = await NewPlatform.new(tether.address, 100, 200);
    await platform1.addToken(tokenName1, 80, 50);
    await platform1.addToken(tokenName2, 90, 60);
    // var init = await platform1.initialize(tether.address, tokenName);

    await tether._mint(platform1.address, 985);

    var val;
    console.log("BEFORE PERIOD")
    var val = await tether.balanceOf.call(platform1.address);
    console.log("Platform balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[1]);
    console.log("Participant 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[2]);
    console.log("Participant 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[3]);
    console.log("Investor 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[4]);
    console.log("Investor 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[5]);
    console.log("Future investor balance: " + val["words"][0]);
    console.log("")

    await tether.approve(platform1.address, 100, {from: accounts[1]});
    var participantName1 = keccak256("participant1");
    await platform1.createParticipant(participantName1, {from: accounts[1]});

    await tether.approve(platform1.address, 100, {from: accounts[2]});
    var participantName2 = keccak256("participant2");
    await platform1.createParticipant(participantName2, {from: accounts[2]});

    await platform1.participantClose();

    await tether.approve(platform1.address, 200, {from: accounts[3]});
    var investorName1 = keccak256("investor1");
    await platform1.createInvestor(tokenName1, 200, investorName1, {from: accounts[3]});

    await tether.approve(platform1.address, 200, {from: accounts[4]});
    var investorName2 = keccak256("investor2");
    await platform1.createInvestor(tokenName1, 100, investorName2, {from: accounts[4]});
    await platform1.createInvestor(tokenName2, 100, investorName2, {from: accounts[4]});

    console.log("AFTER SIGNUP")
    var val = await tether.balanceOf.call(platform1.address);
    console.log("Platform balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[1]);
    console.log("Participant 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[2]);
    console.log("Participant 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[3]);
    console.log("Investor 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[4]);
    console.log("Investor 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[5]);
    console.log("Future investor balance: " + val["words"][0]);
    console.log("")

    await platform1._startTimeCycle();

    await platform1.registerClaim(participantName1, {from: accounts[1]});
    await platform1.registerClaim(participantName2, {from: accounts[2]});

    var tradingAddress = await platform1.tradingAddress.call();

    await platform1.openTrade(tokenName1, 1, 105, {from: accounts[4]});
    await tether.approve(tradingAddress, 110, {from: accounts[3]});
    await platform1.executeTrade(tokenName1, 1, 0, investorName1, {from: accounts[3]});

    await platform1.openTrade(tokenName1, 3, 111, {from: accounts[3]});
    var investorName3 = keccak256("investor3");
    await tether.approve(tradingAddress, 333, {from: accounts[5]});
    await platform1.executeTrade(tokenName1, 3, 1, investorName3, {from: accounts[5]});

    await platform1._resetTimeCycle(); 
    
    var val;
    console.log("AFTER PERIOD")
    var val = await tether.balanceOf.call(platform1.address);
    console.log("Platform balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[1]);
    console.log("Participant 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[2]);
    console.log("Participant 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[3]);
    console.log("Investor 1 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[4]);
    console.log("Investor 2 balance: " + val["words"][0]);
    val = await tether.balanceOf.call(accounts[5]);
    console.log("Future investor balance: " + val["words"][0]);
    console.log("")
  });  
});
