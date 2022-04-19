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
  it("set up investors and participants", async () => {
    // account 0 is the owner of platform
    // account 1 is a participant

    var keccak256 = require("keccak256");
    var tokenName = keccak256("sample");
    var tether = await TetherToken.deployed();
    var platform = await NewPlatform.deployed();// tether.address, 100, 80, 1000);
    var init = await platform.initialize(tether.address, tokenName);

    var mint1 = await tether._mint(accounts[1], 200);
    var approve1 = await tether.approve(platform.address, 100, {from: accounts[1]});
    var participantName1 = keccak256("participant1");
    var participantMade1 = await platform.createParticipant(participantName1, {from: accounts[1]});
    var participantNameCheck = await platform.participantAddressToId.call(
      accounts[1]
    );

    var mint2 = await tether._mint(accounts[2], 200);
    var approve2 = await tether.approve(platform.address, 100, {from: accounts[2]});
    var participantName2 = keccak256("participant2");
    var participantMade2 = await platform.createParticipant(participantName2, {from: accounts[2]});

    var mint3 = await tether._mint(accounts[3], 150);
    var approve3 = await tether.approve(platform.address, 150, {from: accounts[3]});
    var investorName1 = keccak256("investor1");
    var investorMade1 = await platform.createParticipant(investorName1, {from: accounts[3]});

    var mint4 = await tether._mint(accounts[4], 400);
    var approve4 = await tether.approve(platform.address, 400, {from: accounts[4]});
    var investorName2 = keccak256("investor2");
    var investorMade2 = await platform.createParticipant(investorName2, {from: accounts[4]});

    var start = await platform._startTimeCycle();
  });
});

    // createInvestor
    // set isInvestorOpen and isParticipantOpen to closed
    // check createINvestor -> shouldn't be allowed
    // one participant files loss
    // maybe: investor trades part of stake