const BN = require("bn.js");

const InvestorFactory = artifacts.require('InvestorFactory');

contract('investors', () => {
    it("can create investor", async() => {
        const storage = await InvestorFactory.deployed()
        const hashUsername = web3.utils.soliditySha3(new BN('bob'))
        const tx = await storage.createInvestor(1000, hashUsername)
        console.log(tx)
    })
})