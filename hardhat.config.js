/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 
require('@nomiclabs/hardhat-ethers');

module.exports = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      from: "0xf1a565c601ce8c57f7974c7f6fefffc26bffb28c",
      accounts:"remote",
      gas: 8000000
    }
  },
  solidity: "0.8.0",
};
