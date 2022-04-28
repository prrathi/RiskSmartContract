const TetherToken = artifacts.require("Tether");
module.exports = (deployer) => {
    const accounts = web3.eth.getAccounts();
    const keccak256 = require('keccak256')
    deployer.deploy(TetherToken);
}
