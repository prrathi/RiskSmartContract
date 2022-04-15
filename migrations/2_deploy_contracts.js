const NewPlatform = artifacts.require("NewPlatform");
const Token = artifacts.require("Token");
module.exports = (deployer) => {
    const keccak256 = require('keccak256')
    const tokenName = keccak256('sample');
    deployer.deploy(NewPlatform, tokenName, 100, 80);
    // deployer.deploy(Token, {gas: 10000000});
}

