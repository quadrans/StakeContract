// Replace all occurencies of "example" with the name of the contract
const Token = artifacts.require("IronToken");
const Locker = artifacts.require("TokenTimelock");
const Staker = artifacts.require("StakingContract");

const truffleAssert = require('truffle-assertions');
const delorean = require('ganache-time-traveler');
 
contract ("StakingContract", accounts => {

    // ==== Global Test Varables ===============================================================================
    
    // Contracts
    var token 
    var locker
    var staker

    // Time constants
    const HOUR = 60*60
    const DAY = 24*60*60
    const WEEK = 7*24*60*60
    const MONTH = 30*24*60*60
    const YEAR = 365*24*60*60
    
    // Test parameters
    const SUPPLY = 900*1000;
    const date = new Date();
    // const deltaTime = 3; // Number of seconds before release
    const RELEASETIME = Math.floor(date.getTime()/1000) + MONTH;
    
    const BENEFICIARY = accounts[9];
    const OWNER = accounts[0];
    const USER1 =  accounts[1];
    const USER2 =  accounts[2];

    const SNAPSHOT = 0x1;
    let   snapshot; 

    // ==== Functions ===========================================================================================

    function getLog(logs, event, val) {
        for (i=0; i<logs.length; i++) {
            if (logs[i]["event"] == event) {
                return logs[i]["args"][val];
            }
        }
        return null;
    }
 
    function getGas(tx) {
        return tx.receipt.gasUsed;
    }
 
    function toHex(str) {
        var result = '0x';
        for (var i=0; i<str.length; i++) {
          result += str.charCodeAt(i).toString(16);
        }
        return result;
    }
 
    async function showtokenBalance(title, token, addresses) {
        const pad = 20;
        async function line(addr) {
            let str = ''
            let short = addr.toString();
            short = short.substring(0,8)+'...'+short.substring(36,42)
            str += short.padEnd(pad)+'|'
            str += fromWei(await token.balanceOf.call(addr)).padEnd(pad)+'|'
            return str
        }
    
        let str = ''
        str += title.padEnd(pad)+'|'
        str += "Token".padEnd(pad)+'|'
    
        console.log('\x1b[4m%s\x1b[0m', str)        // <=== Underscore trick
        for (addr of addresses) {
            console.log(await line(addr))
        }
        console.log()
    }
    
    function toWei(n) {
        if (typeof(n) == 'number') {
            n = (n).toString()
        }
        return web3.utils.toWei(n)
    }
    
    function fromWei(n) {
        if (typeof(n) == 'number') {
            n = (n).toString()
            console.log(n)
            console.log(typeof(n))
        }
        return web3.utils.fromWei(n)
    }
    
    async function sleep (n) {
        await new Promise(r => setTimeout(r, n*1000));
    }

    async function getBlockchainTime() {
        let b = (await web3.eth.getBlock( await web3.eth.getBlockNumber())).timestamp;
        let date = new Date(b*1000)
        return (date.toLocaleString())
    }

    // ==== Tests ============================================================================================
 
    it("Let's go Martin", async() => {
        // Go back to previous snapshot
        let revert = await delorean.revertToSnapshot(SNAPSHOT);
        console.log('=========================================');
        console.log('Blockchain Date : ', await getBlockchainTime())
        console.log('TIME MACHINE REVERT');
        console.log(revert);
        // Take new snapshot
        snapshot = await delorean.takeSnapshot();
        console.log('=========================================');
        console.log('TIME MACHINE SNAPSHOT');
        console.log(snapshot);
        console.log('Blockchain Date : ', await getBlockchainTime())
        console.log('=========================================');
    });
    
    it("Initialize Contracts", async() => {
        // Do the deploy here so we can change the deploy parameters at will
        token =  await Token.new(SUPPLY);
        locker = await Locker.new(token.address, BENEFICIARY, RELEASETIME);
        staker = await Staker.new(token.address);

        // Show values
        console.log("Owner:  ", OWNER)
        console.log("User1:  ", USER1)
        console.log("User2:  ", USER2)
        console.log("Locker: ", locker.address)
        console.log("Staker: ", staker.address)
        console.log("Benny : ", BENEFICIARY) 
    });

    // ERC20 Data
    it("ERC20 Data", async() => {
        let name = await token.name.call();
        assert.equal(name, "Iron", "Wrong Name");  

        value = await token.symbol.call();
        assert.equal(value, "IRN", "Wrong Symbol");  

        decimals = await token.decimals.call();
        assert.equal(decimals, 18, "Wrong Symbol");  

        value = await token.totalSupply.call();
        assert.equal(value, SUPPLY, "Wrong Supply");  
        
        value = await token.balanceOf.call(OWNER);
        console.log("Total Token Supply: "+value);
        assert.equal(value, SUPPLY, "Wrong Supply");  
    });

    // ==== Locker ===========================================================================================

    it("Check Locker parameters", async() => {
        let t = await locker.token.call();
        assert.equal(t, token.address, "Wrong token address")
        let b = await locker.beneficiary.call();
        assert.equal(b, BENEFICIARY, "Wrong beneficiary")
        let r = await locker.releaseTime.call();
        assert.equal(r, RELEASETIME, "Wrong token address")
    });


    it("Lock 100K tokens", async() => {
        await token.transfer(locker.address, 100000,{from: OWNER});
        value = await token.balanceOf.call(locker.address);
        assert.equal(value, 100000, "Wrong Supply");
    });

    it("Try Early release", async() => {
        await truffleAssert.reverts( locker.release(), truffleAssert.ErrorType.REVERT, "reverts" );
    });
    
    it("Do proper release", async() => {
        // More than a month later...
        await delorean.advanceTimeAndBlock(MONTH+DAY)
        await locker.release()
        value = await token.balanceOf.call(BENEFICIARY);
        assert.equal(value, 100000, "Wrong Supply");
    });

    // ==== Staker ===========================================================================================


    it("Check Staker parameters", async() => {    
        let s = await staker.stakedTokens.call();
        assert.equal(s,0,"-1-");
        let r = await staker.rewardedTokens.call();
        assert.equal(r,0,"-2-");
    });

    it("Transfer 100K -> User1", async() => {
        await token.transfer(USER1, 100000,{from: OWNER});
        value = await token.balanceOf.call(USER1);
        assert.equal(value, 100000, "Wrong Supply");
    });

    it("Transfer 200K -> User2", async() => {
        await token.transfer(USER2, 200000,{from: OWNER});
        value = await token.balanceOf.call(USER2);
        assert.equal(value.toNumber(), 200000, "Wrong Supply");
    });

    it("Try Cheap Staking", async() => {
        await token.approve(staker.address, 100000, {from: USER2});
        await token.allowance(USER2, staker.address)
        await truffleAssert.reverts( staker.stake(5, {from: USER2}), truffleAssert.ErrorType.REVERT, "reverts" );
    });

    it("Proper Staking", async() => {
        await staker.stake(100000, {from: USER2})
        let b = await token.balanceOf(staker.address);
        assert.equal(b.toNumber(), 100000, "Wrong Stake");
        let h = await staker.StakeHolders.call(USER2);
    });


    it("Feed Staker", async() => {
        await token.transfer(staker.address, 100000,{from: OWNER});
        value = await token.balanceOf.call(staker.address);
        assert.equal(value.toNumber(), 200000, "Wrong Supply");

        await showtokenBalance("IronToken", token, [OWNER, USER1, USER2, locker.address, staker.address,BENEFICIARY])
    });


    async function StakeTime (time) {
        // Get initial balances
        console.log("    - time    : ", time)
        let ib_s = await token.balanceOf(staker.address);
        let ib_u = await token.balanceOf(USER1);
        
        // Stake 100000
        let stake = 100000
        await token.approve(staker.address, stake, {from: USER1});
        await staker.stake(stake, {from: USER1})
        let b = await token.balanceOf(staker.address);
        assert.equal(b.toNumber(), ib_s.toNumber()+stake, "Wrong Balance for staker");

        // FastForward time 
        await delorean.advanceTimeAndBlock(time)

        let i = await staker.getInterest({from: USER1})
        console.log("    - interest: ", i.toNumber())

        // Widthdraw
        await staker.withdraw({from: USER1})

        // Check
        b = await token.balanceOf(staker.address);
        assert.equal(b.toNumber(), (ib_s-i.toNumber()), "Wrong Remains for staker");
        let u = await token.balanceOf(USER1);
        assert.equal(u.toNumber(), ib_u.toNumber()+i.toNumber(), "Wrong balance for user1");
        console.log("    - user balance : ", u.toNumber())
    }
    
    it("1 hour stake", async() => {
        await StakeTime(HOUR);
    });

    it("1 Day stake", async() => {
        await StakeTime(DAY);
    });

    it("1 Week stake", async() => {
        await StakeTime(WEEK);
    });
    
    it("1 Month stake", async() => {
        await StakeTime(MONTH);
    });

    it("1 year stake", async() => {
        await StakeTime(YEAR);
    });

    // Short stakes
    it("1 Minute stake", async() => {
        await StakeTime(60);
    });

    it("5 minute stake", async() => {
        await StakeTime(2251);      // minimum amount of time to get >0 interest = 37'30"
    });


    it("", async() => {
        
    });

    it("", async() => {
        
    });


    // // Call
    // it("Test Declaration", async() => {
    //     let instance= await example.deployed();
    //     value = await instance.method.call(accounts[0]);
    //     assert.equal(value, expected, "Error Message");  
    // });
 
 
    // // Tx
    // it("Test Declaration", async() => {
    //     let instance= await example.deployed();
    //     let tx = await instance.method(param, {from: accounts[1]});
    //     output  = getLog(tx.receipt.logs,"EventName","_field");
    //     assert.equal(output, expected, "Error Message");
    // });
 
 
    // ==== Reverts Time =====================================================================================
 
    it("Let's go home Martin...", async() => {
        console.log('=========================================');
        console.log('TIME MACHINE SNAPSHOT');
        console.log(snapshot);
        console.log('Blockchain Date : ', await getBlockchainTime())
        console.log('=========================================');
        let revert = await delorean.revertToSnapshot(SNAPSHOT);
        console.log('=========================================');
        console.log('Blockchain Date : ', await getBlockchainTime())
        console.log('TIME MACHINE REVERT');
        console.log(revert);
    });
});