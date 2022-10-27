/* global describe it before ethers */

const { assert, expect } = require('chai')
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe('Test', async function () {

    let zero_address
    let ONE_MONTH_IN_SECS
    let deployer, user1, user2
    let mumAddr
    let MF
    let latestId
    let latestExpTime

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        MF = await hre.ethers.getContractFactory("MumbaiFarsi");
        mumAddr = await MF.deploy();
        MF = await hre.ethers.getContractFactory("MainnetFarsi");
        mainAddr = await MF.deploy();
    }) 

    it('should mint freely for every user on mumbai', async () => {
        latestExpTime = ((await time.latest()) + ONE_MONTH_IN_SECS)
        await mumAddr.connect(deployer).mint("tokenURI", latestExpTime)

        latestId = await mumAddr.getId("tokenURI", deployer.address, latestExpTime)
        
        assert.equal(
            await mumAddr.totalSupply(latestId),
            1
        )
    })

    it('should check collecting fee', async () => {
        await expect(
            mainAddr.connect(user1).collect(
                latestId,
                "tokenURI",
                deployer.address,
                latestExpTime,
                [user1.address, user2.address], 
                [6000, 4000],
                { value: await mainAddr.fee(latestId) - 1 }
            )
        ).to.be.revertedWith(
            "Mainnet Farsi: insufficient fee"
        );
        
        // await mainAddr.connect(user1).collect(
        //     latestId,
        //     "tokenURI",
        //     deployer.address,
        //     latestExpTime,
        //     [user1.address], 
        //     [10000],
        //     { value: await mainAddr.fee(latestId) }
        // )
    })

    it('should not accept different length of address and fraction', async () => {
        await expect(
            mainAddr.connect(user1).collect(
                latestId,
                "tokenURI",
                deployer.address,
                latestExpTime,
                [user1.address, user2.address], 
                [10000],
                { value: await mainAddr.fee(latestId) }
            )
        ).to.be.revertedWith(
            "FeeManager: receivers and fractions must be the same length"
        );
        
        // await mainAddr.connect(user1).collect(
        //     latestId,
        //     "tokenURI",
        //     deployer.address,
        //     latestExpTime,
        //     [user1.address], 
        //     [10000],
        //     { value: await mainAddr.fee(latestId) }
        // )
    })

    // it('should collect on mainnet', async () => {
    //     await mainAddr.connect(user1).collect(
    //         latestId,
    //         "tokenURI",
    //         deployer.address,
    //         latestExpTime,
    //         [user1.address, user2.address], 
    //         [60, 40],
    //         { value: await mainAddr.fee(latestId) }
    //     )

    //     latestId = await mumAddr.getId("tokenURI", user1.address, 5)
        
    //     assert.equal(
    //         await mumAddr.totalSupply(id),
    //         1
    //     )
    // })

})
