const Taxicab = artifacts.require("Taxicab.sol");
const NumerNFT = artifacts.require("NumerNFT.sol");

module.exports = deployer => {
  deployer.deploy(Taxicab);
  deployer.deploy(NumerNFT);
};
