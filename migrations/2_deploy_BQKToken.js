const BQKToken = artifacts.require("BQKToken");

module.exports = function (deployer) {
    deployer.deploy(BQKToken);
};