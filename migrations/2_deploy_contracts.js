const DECA = artifacts.require("DECA");
module.exports = function (deployer) {
    module.exports = function (deployer) {
        deployer.deploy(DECA, {
            gas: 6712390
        });
    };
};
