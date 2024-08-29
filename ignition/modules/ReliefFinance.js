const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const rwaTokenaddress = "0x4563554284aa7148d6e6d0351519e954ba3b6e02";

module.exports = buildModule("ReliefFinanceModule", (m) => {
  const rwaTokenAddress = m.getParameter("rwaToken", rwaTokenaddress);

  const mycontract = m.contract("ReliefFinance", [rwaTokenAddress]);

  return { mycontract };
});
