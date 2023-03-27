const BQKToken = artifacts.require("BQKToken");
const BidNow = artifacts.require("BidNow");

module.exports = function (deployer) {
    deployer.deploy(BQKToken).then(function () {
        return deployer.deploy(BidNow, BQKToken.address);
    });
};