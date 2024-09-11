const hre = require("hardhat");
const { ethers } = require("ethers");

async function main() {
  const ReliefFinance = await hre.ethers.getContractFactory("ReliefFinance");

  const reliefFinance = await ReliefFinance.deploy();

  await reliefFinance.deployed();

  console.log(`contract deployed to ${reliefFinance.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
