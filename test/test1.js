const NewPlatform = artifacts.require("../contracts/NewPlatform.sol")
// const TetherToken = artifacts.require("TetherToken")
const assert = require('assert')
const usdt = require('./abi/usdt')
const USDT = '0xB2a0d59F3f952805b4d44e5C7c340CC83280D1E0'
const {ourAddress} = process.env
const data = require('./abi/usdt')
const usdtContract = new web3.eth.Contract(data, USDT)
contract('NewPlatform', (accounts) => {
    it("make participant", async() => {
        const keccak256 = require('keccak256')
        const tokenName = keccak256('sample')
        const platform = await NewPlatform.deployed(tokenName, 100, 80, 1000)
        const value = await usdtContract.methods.balanceOf(accounts[0]).call()
        // const transfer = await usdtContract.methods.transferFrom(accounts[0], platform.address, 110)
        // const value2 = await usdtContract.methods.balanceOf(platform.address).call()
        // assert.equal(value + 110, value2)

        // const participantName = keccak256('participant1')
        // const participantMade = await platform.createParticipant(participantName)
        // const participantNameCheck = await platform.participantAddressToId(accounts[0])
        // assert.equal(participantNameCheck, participantName, "not working")
    })
}) 