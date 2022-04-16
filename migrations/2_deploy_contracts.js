const NewPlatform = artifacts.require("NewPlatform");
const Token = artifacts.require("Token");
module.exports = (deployer) => {
    const keccak256 = require('keccak256')
    const tokenName = keccak256('sample');
    deployer.deploy(NewPlatform, tokenName, 100, 80, 1000);
    // deployer.deploy(Token, {gas: 10000000});
}

// createParticipant x2
// createInvestor
// set isInvestorOpen and isParticipantOpen to closed
// check createINvestor -> shouldn't be allowed
// one participant files loss
// maybe: investor trades part of stake

