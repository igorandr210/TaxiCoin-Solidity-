var TaxiCoin =artifacts.require("./Escrow");
module.exports = function(deployer) {
  deployer.deploy(TaxiCoin);
};

