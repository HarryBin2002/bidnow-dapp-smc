// const Token = artifacts.require("Token");
// const BidNow = artifacts.require("BidNow");

// module.exports = function (deployer) {
//     deployer.deploy(Token).then(function () {
//         return deployer.deploy(BidNow, Token.address);
//     });
// };


const Token = artifacts.require("Token");
const BidNow = artifacts.require("BidNow");

module.exports = async function (deployer) {
  await deployer.deploy(Token);
  const tokenInstance = await Token.deployed();
  console.log("Token contract deployed at address:", tokenInstance.address);
  
  await deployer.deploy(BidNow, tokenInstance.address);
};