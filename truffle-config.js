const HDWalletProvider = require('@truffle/hdwallet-provider');

// if you use mnenomic, by default: main wallet is used to sign transactions
// const mnemonic = "pipe stumble payment grace brave walk torch hedgehog empty elite coil shoe";

const privateKeyWallet = "c3c94a9fcb365bd57608fc944d1aa27ab139f73d3fbd1421ec498f78c512b6ad"; 

const infuraProjectId = "957667d02c8140f2a928416b623282f2";
const infuraProvider = new HDWalletProvider(privateKeyWallet, `https://goerli.infura.io/v3/${infuraProjectId}`);

const bscProvider = new HDWalletProvider(privateKeyWallet, 'https://data-seed-prebsc-1-s1.binance.org:8545');

module.exports = {

  networks: {
    goerli: {
      provider: () => infuraProvider,
      network_id: 5,
      chain_id: 5,
      gas: 20000000,
      gasPrice: 10000000000, // 20 gwei
      // confirmations: 2,
      // timeoutBlocks: 2,
      skipDryRun: true
    },

    bscTestnet: {
      provider: () => bscProvider,
      network_id: 97,
      gas: 20000000
    },

    development: {
      host: "127.0.0.1",
      port: 7545, // default Ganache port
      network_id: "*", // match any network id
    },
  },

  compilers: {
    solc: {
      version: "^0.8.0",
    }
  },
};
