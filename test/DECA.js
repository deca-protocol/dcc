const DECA = artifacts.require('./DECA.sol')

// fix legacy web3 bugs
web3.toAsciiOriginal = web3.toAscii;
web3.toAscii = function (input) {
    return web3.toAsciiOriginal(input).replace(/\u0000/g, '')
}

let accCounter = 0;

function increaseTime(duration) {
    const id = Date.now()

    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_increaseTime',
            params: [duration],
            id: id,
        }, err1 => {
            if (err1) return reject(err1)

            web3.currentProvider.send({
                jsonrpc: '2.0',
                method: 'evm_mine',
                id: id + 1,
            }, (err2, res) => {
                return err2 ? reject(err2) : resolve(res)
            })
        })
    })
}

function latestTime() {
    return web3.eth.getBlock('latest').timestamp;
}

//bypass testrpc bug
async function getHighBalance() {
    var accounts = await web3.eth.getAccounts();
    var acc = accounts[accCounter];
    console.dir(acc)
    var b = await web3.eth.getBalance(acc);

    console.dir(b)
    let high = {
        "address": acc,
        "balance": b
    }
    accCounter++;

    return high;
}

const duration = {
    seconds: function (val) {
        return val
    },
    minutes: function (val) {
        return val * this.seconds(60)
    },
    hours: function (val) {
        return val * this.minutes(60)
    },
    days: function (val) {
        return val * this.hours(24)
    },
    weeks: function (val) {
        return val * this.days(7)
    },
    years: function (val) {
        return val * this.days(365)
    }
};


contract('DECA', function (accs) {
    beforeEach(async function () {
        this.creator = await getHighBalance();

        this.deca = await DECA.new({
            from: this.creator.address,
            gas: 6712390
        })

    }),
        describe('check pause', function () {
            it('should get/set pause', async function () {
                let p = await this.deca.getPause.call();
                assert.equal(false, p, "pause should be disabled")
                await this.deca.setPause(true, {from: this.creator.address, gas: 6712390})
                p = await this.deca.getPause.call();
                assert.equal(true, p, "pause should be enabled")
            })
            it('should fail on pay', async function () {
                await this.deca.setPause(true, {from: this.creator.address, gas: 6712390})
                let wasErr = false;
                try {
                    let rs = await web3.eth.sendTransaction({
                        from: this.creator.address,
                        to: this.deca.address,
                        value: 225,
                        gas: 6712390
                    });
                } catch (err) {
                    wasErr = true;
                }
                await this.deca.setPause(false, {from: this.creator.address, gas: 6712390})

                wasErr = false;
                try {
                    let rs = await web3.eth.sendTransaction({
                        from: this.creator.address,
                        to: this.deca.address,
                        value: 225,
                        gas: 6712390
                    });
                } catch (err) {
                    wasErr = true;
                }
                assert.equal(false, wasErr, "pause should work")
            })
            it('check intruder pause', async function () {
                var sender = await getHighBalance();
                await increaseTime(duration.days(1))
                await web3.eth.sendTransaction({
                    from: sender.address,
                    to: this.deca.address,
                    value: 1,
                    gas: 6712390
                });
                let wasErr = false;
                try {
                    await this.deca.setPause(true, {from: sender.address, gas: 6712390})
                } catch (err) {
                    wasErr = true;
                }
                assert.equal(true, wasErr, "only owner could pause")
                let own = await this.deca.owner();
                assert.equal(this.creator.address, own, "owner does not match")
            })

        })

    describe('check crowdsale dates', function () {
        it('check preICOEnds', async function () {
            var sender = await getHighBalance();
            await increaseTime(duration.days(1))
            await web3.eth.sendTransaction({
                from: sender.address,
                to: this.deca.address,
                value: 1,
                gas: 6712390
            });
            let bonus2Ends = await this.deca.balanceOf.call(sender.address)

            assert.equal(bonus2Ends.toString(10), '300', "preICOEnds wrong token balance")
        })
        it('check bonus1Ends', async function () {
            var sender = await getHighBalance();
            await increaseTime(duration.days(7) + duration.hours(1))
            await web3.eth.sendTransaction({
                from: sender.address,
                to: this.deca.address,
                value: 1,
                gas: 6712390
            });
            let bonus2Ends = await this.deca.balanceOf.call(sender.address)

            assert.equal(bonus2Ends.toString(10), '275', "bonus1Ends wrong token balance")
        })
        it('check bonus2Ends', async function () {
            var sender = await getHighBalance();
            await increaseTime(duration.weeks(3) + duration.hours(1))
            await web3.eth.sendTransaction({
                from: sender.address,
                to: this.deca.address,
                value: 1,
                gas: 6712390
            });
            let bonus2Ends = await this.deca.balanceOf.call(sender.address)

            assert.equal(bonus2Ends.toString(10), '250', "bonus2Ends wrong token balance")
        })
        it('check endDate', async function () {
            await increaseTime(duration.weeks(11) + duration.hours(1))

            let wasErr = false;
            try {
                let rs = await web3.eth.sendTransaction({
                    from: this.creator.address,
                    to: this.deca.address,
                    value: 225,
                    gas: 6712390
                });
            } catch (err) {
                wasErr = true;
            }

            assert.equal(true, wasErr, "crowdsale should be stopped")
        })

    })
    // SOMEHOW THIS FUNCTIONS TEST WORKED IN ROPSTEN
//    describe('transferAnyERC20Token', async function () {
//        it('check transfer from external', async function () {
//            this.deca2 = await DECA.new({
//                from: this.creator.address,
//                gas: 6712390
//            })
//
//            var sender = await getHighBalance();
//            await web3.eth.sendTransaction({
//                from: sender.address,
//                to: this.deca2.address,
//                value: 1,
//                gas: 6712390
//            });
//            let deca2Balance = await this.deca2.balanceOf.call(sender.address)
//            console.log('DECA2 BALANCE : ', deca2Balance.toString(10))
//
//            assert.equal(deca2Balance.toString(10), '300', " sender should have balance")
//
//            let wasErr = false;
//            try {
//                let ok = await this.deca.transferAnyERC20Token(this.deca2.address, 1, {
//                    from: this.creator.address,
//                    gas: 6712390
//                })
//                assert.equal(true, ok, "transferAnyERC20Token should return positive result")
//            } catch (err) {
//                console.dir(err)
//                wasErr = true;
//            }
//            deca2Balance = await this.deca2.balanceOf.call(sender.address)
//
//            assert.equal(deca2Balance.toString(10), '0', " sender should have 0 on balance")
//        })
//    })
//    describe('check payout', async function () {
//        it('check getETH', async function () {
//            let decaBalance = await web3.eth.getBalance(this.deca.address);
//            assert.equal(decaBalance.toString(10), '0', " wrong contract balance")
//            var sender = await getHighBalance();
//            await web3.eth.sendTransaction({
//                from: sender.address,
//                to: this.deca.address,
//                value: 1000,
//                gas: 6712390
//            });
//            decaBalance = await web3.eth.getBalance(this.deca.address);
//            assert.equal(decaBalance.toString(10), '1000', " wrong contract balance")
//            let senderTokenBalance = await this.deca.balanceOf.call(sender.address)
//            assert.equal(senderTokenBalance.toString(10), '200000', " wrong sender balance")
//            await increaseTime(duration.weeks(12));
//            let wasErr = false;
//            try {
//                await this.deca.getETH({from: this.creator.address, gas: 6712390})
//            } catch (err) {
//                console.dir(err)
//                wasErr = true;
//            }
//            assert.equal(false, wasErr, "getETH not possible to test because of bug in truffle, check status of bug: https://github.com/trufflesuite/truffle/issues/2811")
//            decaBalance = await web3.eth.getBalance(this.deca.address);
//            assert.equal(decaBalance.toString(10), '0', " balance of the DECA expected to be empty")
//
//
//        })
//    })

})
