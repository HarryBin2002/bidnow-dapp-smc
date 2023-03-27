const HDWalletProvider = require('@truffle/hdwallet-provider');

// if you use mnenomic, by default: main wallet is used to sign transactions
// const mnemonic = "pipe stumble payment grace brave walk torch hedgehog empty elite coil shoe";

const privateKey = "dbf48d914c013b586ec11b9e9a2ed1a19912aaf1a312c110c15b1b576cebcc3f"; 
const infuraProjectId = "33f63adf6d1a451980abc4cf997c18a4";


module.exports = {
  
  networks: {
    goerli: {
      provider: () => new HDWalletProvider(privateKey, `https://goerli.infura.io/v3/${infuraProjectId}`),
      network_id: 5,
      chain_id: 5,
      gas: 10000000,
      gasPrice: 10000000000, // 20 gwei
      // confirmations: 2,
      // timeoutBlocks: 2,
      skipDryRun: true
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
