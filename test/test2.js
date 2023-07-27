/* global describe it before ethers */

const { assert, expect } = require('chai')
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { deployFee, callFee } = require("../scripts/utils/gasEstimator.js");

describe('Test', async function () {

  let test

    before(async function () {
        const testCont = await hre.ethers.getContractFactory("expTest")
        test = await testCont.deploy()
    }) 


    it('test power', async () => {
      console.log( 
        ethers.utils.formatEther(
          await test.powerInt(
            ((-1) * 10 ** 18), 
            ethers.utils.parseEther("2")
          )
        )
      )
    })

    // it('should not mint 721 with same token id', async () => {
    //     await expect(
    //         kat721.connect(deployer).safeMint("tokenURI", latestExpTime, 0, ["data", "tag2", "tag3"])
    //     ).to.be.revertedWith(
    //         "ERC721: token already minted"
    //     );
    // })

    // it('should not mint 721 with same token uri', async () => {
    //     await expect(
    //         kat721.connect(deployer).safeMint("tokenURI", latestExpTime + 1, 0, ["data", "tag2", "tag3"])
    //     ).to.be.revertedWith(
    //         "DataStorage: uri registered already"
    //     );
    // })

    // it('should check collecting fee', async () => {
    //     await expect(
    //         factory.connect(user1).collect(
    //             latestId,
    //             "tokenURI",
    //             deployer.address,
    //             latestExpTime,
    //             [user1.address, user2.address], 
    //             [6000, 4000],
    //             { value: (await factory.fee(latestId) - 100).toString() }
    //         )
    //     ).to.be.revertedWith(
    //         "Mainnet Farsi: insufficient fee"
    //     );
    // })

    // it('should not accept different length of address and fraction', async () => {
    //     await expect(
    //         factory.connect(user1).collect(
    //             latestId,
    //             "tokenURI",
    //             deployer.address,
    //             latestExpTime,
    //             [user1.address, user2.address], 
    //             [10000],
    //             { value: await factory.fee(latestId) }
    //         )
    //     ).to.be.revertedWith(
    //         "FeeManager: receivers and fractions must be the same length"
    //     );
    // })

    // it('check fee before collect 1', async () => {
        
    //     assert.equal(
    //         await factory.fee(latestId),
    //         10 ** 18
    //     )
    // })

    // it('should not collect same token for same user', async () => {
        
    //     await expect(
    //         factory.connect(user1).collect(
    //             latestId,
    //             "tokenURI",
    //             deployer.address,
    //             latestExpTime,
    //             [user1.address, user2.address], 
    //             [6000, 4000],
    //             { value: await factory.fee(latestId) }
    //         )
    //     ).to.be.revertedWith(
    //         "Mainnet Farsi: token collected already"
    //     );
    // })

    // it('should have correct balances after collect 1', async () => {
        
    //     assert.equal(
    //         await factory.totalSupply(latestId),
    //         11
    //     )
    //     assert.equal(
    //         await factory.balanceOf(deployer.address, latestId),
    //         10
    //     )
    //     assert.equal(
    //         await factory.balanceOf(user1.address, latestId),
    //         1
    //     )
    // })

    // it('check fee before collect 2', async () => {
        
    //     assert.equal(
    //         await factory.fee(latestId),
    //         1.275 * 10 ** 18 - 100
    //     )
    // })

    // it('should collect 2 correctly on mainnet', async () => {
        
    //     await factory.connect(user2).collect(
    //         latestId,
    //         "tokenURI",
    //         deployer.address,
    //         latestExpTime,
    //         [user1.address, user2.address], 
    //         [6000, 4000],
    //         { value: await factory.fee(latestId) }
    //     )
    // })

    // it('check fee before collect 3', async () => {
        
    //     assert.equal(
    //         await factory.fee(latestId),
    //         1.3 * 10 ** 18 
    //     )
    // })

    // it('should have correct balances after collect 2', async () => {
        
    //     assert.equal(
    //         await factory.totalSupply(latestId),
    //         12
    //     )
    //     assert.equal(
    //         await factory.balanceOf(deployer.address, latestId),
    //         10
    //     )
    //     assert.equal(
    //         await factory.balanceOf(user1.address, latestId),
    //         1
    //     )
    //     assert.equal(
    //         await factory.balanceOf(user2.address, latestId),
    //         1
    //     )
    // })

    // it('should revert after expire time', async () => {

    //     await time.increaseTo(latestExpTime + 1);

    //     await expect(
    //         factory.connect(user1).collect(
    //             latestId,
    //             "tokenURI",
    //             deployer.address,
    //             latestExpTime,
    //             [user1.address, user2.address], 
    //             [10000],
    //             { value: await factory.fee(latestId) }
    //         )
    //     ).to.be.revertedWith(
    //         "Mainnet Farsi: token sale time is expired"
    //     );
    // })

    // it('should safe mint global', async () => {
    //     await kat721.safeMintGlobal(
    //         "tokenURI2", 
    //         latestExpTime,
    //         0, 
    //         ["data", "tag2", "tag3"]
    //     )
    // })

})
