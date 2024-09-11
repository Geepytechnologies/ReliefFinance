require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomicfoundation/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
const {
  POLYGON_API_URL,
  POLYGON_PRIVATE_KEY,
  GOERLI_API_URL,
  GOERLI_PRIVATE_KEY,
  SEPOLIA_API_URL,
  SEPOLIA_PRIVATE_KEY,
  POLYGONSCAN,
  BNBTESTNET_PRIVATE_KEY,
  ASSETCHAIN_PRIVATE_KEY,
} = process.env;

module.exports = {
  solidity: "0.8.24",
  networks: {
    goerli: {
      url: `${GOERLI_API_URL}`,
      accounts: [GOERLI_PRIVATE_KEY],
    },
    polygon: {
      url: POLYGON_API_URL,
      accounts: [`0x${POLYGON_PRIVATE_KEY}`],
    },
    sepolia: {
      url: SEPOLIA_API_URL,
      accounts: [`0x${SEPOLIA_PRIVATE_KEY}`],
    },
    bnbtestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [`0x${BNBTESTNET_PRIVATE_KEY}`],
    },
    assetchain_testnet: {
      url: "https://enugu-rpc.assetchain.org/",
      accounts: [`0x${ASSETCHAIN_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: POLYGONSCAN,
    customChains: [
      {
        network: "assetchain_test",
        chainId: 42421,
        urls: {
          apiURL: "https://scan-testnet.assetchain.org/api",
          browserURL: "https://scan-testnet.assetchain.org/",
        },
      },
    ],
  },
};
