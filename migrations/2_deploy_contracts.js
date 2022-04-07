const InvestorFactory = artifacts.require('InvestorFactory');
module.exports = (deployer) => {
    deployer.deploy(InvestorFactory, {gas: 10000000});
}

