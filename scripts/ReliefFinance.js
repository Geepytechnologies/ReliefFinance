const hre = require("hardhat");
const { ethers } = require("ethers");

async function main() {
  const amount = "1";
  const decimals = 18;
  const parsedAmount = ethers.utils.parseUnits(amount, decimals);
  const ReliefFinance = await hre.ethers.getContractFactory("ReliefFinance");
  const election = await ReliefFinance.attach(
    "0x857c7FF5Be4a640B7E27a6B0A6f377Ba497068b6"
  );

  const reliefFinance = await ReliefFinance.deploy();

  await reliefFinance.deployed();

  console.log(`contract deployed to ${reliefFinance.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
