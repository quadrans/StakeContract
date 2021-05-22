var Token = artifacts.require("IronToken");
var Locker = artifacts.require("TokenTimelock");
var Staker = artifacts.require("StakingContract");

var date = new Date();
var delta = 31*24*60*60; // Number of seconds before release
var releaseTime = Math.floor(date.getTime()/1000) + delta;

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(Token, 900000);
  // those deploys are done in the test
  // await deployer.deploy(Locker, Token.address, accounts[0], releaseTime);
  // await deployer.deploy(Staker, Token.address);
};