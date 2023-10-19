require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require('hardhat-contract-sizer');

const { ACCOUNT, POLYGONSCAN_API_KEY } = require('./secret.json');

module.exports = {
  solidity: {
    version: "0.8.21",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        // runs: 200,
      },
    },
  },
  networks: {
    mainnet: {
      url: `https://eth.llamarpc.com`,
      accounts: [`0x${ACCOUNT}`],
      chainId : 1
    },
    polygon: {
      url: `https://polygon-rpc.com/`,
      accounts: [`0x${ACCOUNT}`],
      chainId : 137
    },
    polygonMumbai: {
      url: `https://rpc-mumbai.maticvigil.com/`,
      accounts: [`0x${ACCOUNT}`],
      chainId : 80001
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
  etherscan: {
      apiKey: {
        polygon: `${POLYGONSCAN_API_KEY}`,
        polygonMumbai: `${POLYGONSCAN_API_KEY}`,
      }
    },

  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: false,
  },
};