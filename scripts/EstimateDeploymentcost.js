const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const ReliefFinance = await hre.ethers.getContractFactory("ReliefFinance");
  const estimatedGas = await ReliefFinance.signer.estimateGas(
    ReliefFinance.getDeployTransaction() // Transaction object with constructor arguments
  );

  console.log("Estimated Gas Cost:", estimatedGas.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
