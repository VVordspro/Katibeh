/* global describe it before ethers */

const { assert, expect } = require('chai')

describe('TransactionFeeTest', async function () {

    let zero_address
    let deployer, user1, user2
    let mumAddr
    let MF
    let lastId

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        MF = await hre.ethers.getContractFactory("MumbaiFarsi");
        mumAddr = await MF.deploy();
        MF = await hre.ethers.getContractFactory("MainnetFarsi");
        mainAddr = await MF.deploy();
    }) 

    it('should mint freely for every user on mumbai', async () => {
        await mumAddr.connect(user1).mint("tokenURI", 5)

        lastId = await mumAddr.getId("tokenURI", user1.address, 5)
        
        assert.equal(
            await mumAddr.totalSupply(id),
            10 **18
        )
    })

    // it('should collect on mainnet', async () => {
    //     await mumAddr.connect(user1).mint("tokenURI", 5)

    //     lastId = await mumAddr.getId("tokenURI", user1.address, 5)
        
    //     assert.equal(
    //         await mumAddr.totalSupply(id),
    //         10 **18
    //     )
    // })

})
