// const platform= artifacts.require("NewPlatform");
const TetherToken = artifacts.require("Tether");
const Token = artifacts.require("Token");
module.exports = (deployer) => {
    const accounts = web3.eth.getAccounts();
    const keccak256 = require('keccak256')
    const tokenName = keccak256('sample');
    deployer.deploy(TetherToken);
    // deployer.deploy(NewPlatform, 100, 80, 200);
    // deployer.deploy(Token, tokenName, NewPlatform.address);
}
