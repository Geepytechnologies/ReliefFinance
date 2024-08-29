const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("ReliefFinanceModule", (m) => {
  const mycontract = m.contract("ReliefFinance");

  return { mycontract };
});
