var DECAToken = artifacts.require("DECAToken");

module.exports = function(deployer) {
    const name = "DEcentralized CArbon tokens";
    const symbol = "DECA";
    const decimals = 18;
    deployer.deploy(DECAToken, name, symbol, decimals);
};
