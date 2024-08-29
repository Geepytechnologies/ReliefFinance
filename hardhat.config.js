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
  },
  etherscan: {
    apiKey: POLYGONSCAN,
  },
};
