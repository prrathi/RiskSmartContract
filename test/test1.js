var NewPlatform = artifacts.require("../contracts/NewPlatform.sol");
var TetherToken = artifacts.require("../contracts/Tether.sol")
var Token = artifacts.require("../contracts/Token.sol")
var assert = require("assert");
// var usdt = require('./abi/usdt')
// var USDT = '0xB2a0d59F3f952805b4d44e5C7c340CC83280D1E0'
// var {ourAddress} = process.env
// var data = require('./abi/usdt')
// var usdtContract = new web3.eth.Contract(data, USDT)
contract("NewPlatform", (accounts) => {
  it("new platform", async () => {
    // account 0 is the owner of platform
    // account 1 is a participant

    var keccak256 = require("keccak256");
    var tokenName = keccak256("sample");
    var tether = await TetherToken.deployed();
    var platform1 = await NewPlatform.new(100, 80, 200);// tether.address, 100, 80, 1000);
    var init = await platform1.initialize(tether.address, tokenName);

    await tether._mint(platform1.address, 1000);
    await tether._mint(accounts[1], 100);
    await tether._mint(accounts[2], 100);
    await tether._mint(accounts[3], 150);
    await tether._mint(accounts[4], 400);

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
    console.log("")

    await tether.approve(platform1.address, 100, {from: accounts[1]});
    var participantName1 = keccak256("participant1");
    await platform1.createParticipant(participantName1, {from: accounts[1]});

    await tether.approve(platform1.address, 100, {from: accounts[2]});
    var participantName2 = keccak256("participant2");
    await platform1.createParticipant(participantName2, {from: accounts[2]});

    await tether.approve(platform1.address, 150, {from: accounts[3]});
    var investorName1 = keccak256("investor1");
    await platform1.createInvestor(150, investorName1, {from: accounts[3]});

    await tether.approve(platform1.address, 400, {from: accounts[4]});
    var investorName2 = keccak256("investor2");
    await platform1.createInvestor(400, investorName2, {from: accounts[4]});

    var val;
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
    console.log("")

    await platform1._startTimeCycle();

    await platform1.registerClaim(participantName1, {from: accounts[1]});

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
    console.log("")
  });
});

    // createInvestor
    // set isInvestorOpen and isParticipantOpen to closed
    // check createINvestor -> shouldn't be allowed
    // one participant files loss
    // maybe: investor trades part of stake