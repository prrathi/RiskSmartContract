const PlatformSetup = artifacts.require('PlatformSetup');
module.exports = (deployer) => {
    deployer.deploy(PlatformSetup, {gas: 10000000});
}

