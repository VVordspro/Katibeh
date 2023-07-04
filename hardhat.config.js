require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require('hardhat-contract-sizer');

const { ACCOUNT, POLYGONSCAN_API_KEY, ETHERSCAN_API_KEY } = require('./secret.json');

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
    },
  },
  networks: {
    mainnet: {
      url: `https://eth.llamarpc.com`,
      accounts: [`0x${ACCOUNT}`],
    },
    polygon: {
      url: `https://polygon-rpc.com/`,
      accounts: [`0x${ACCOUNT}`],
    },
    polygonMumbai: {
      url: `https://rpc-mumbai.maticvigil.com/`,
      accounts: [`0x${ACCOUNT}`],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`,
      accounts: [`0x${ACCOUNT}`],
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`,
      accounts: [`0x${ACCOUNT}`],
    },
    // goerli: {
    //   url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
    //   accounts: [`0x${ACCOUNT}`],
    // },
    avalancheFujiTestnet: {
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts: [`0x${ACCOUNT}`],
    },
    xdai: {
      url: `https://rpc.gnosischain.com`,
      accounts: [`0x${ACCOUNT}`],
    },
    sokol: {
      url: `https://sokol.poa.network`,
      accounts: [`0x${ACCOUNT}`],
    },
  },


  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
};