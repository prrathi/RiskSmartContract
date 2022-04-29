const TetherToken = artifacts.require("Tether");
const NewPlatform = artifacts.require("NewPlatform");
const Trading = artifacts.require("Trading");
const Token = artifacts.require("Token");
module.exports = (deployer) => {
    const accounts = web3.eth.getAccounts();
    const keccak256 = require('keccak256')
    deployer.deploy(TetherToken);
}
