/* global describe it before ethers */

const { assert, expect } = require('chai')
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe('Test', async function () {

    let zero_address
    let ONE_MONTH_IN_SECS
    let deployer, user1, user2
    let mum721
    let mum1155
    let main1155
    let latestId
    let latestExpTime

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
        const accounts = await ethers.getSigners();
        [deployer, user1, user2] = accounts
        let mumbai721 = await hre.ethers.getContractFactory("Mumbai721");
        mum721 = await mumbai721.deploy();
        let mumbai1155 = await hre.ethers.getContractFactory("Mumbai1155");
        mum1155 = await mumbai1155.deploy();
        let mainnet1155 = await hre.ethers.getContractFactory("Mainnet1155");
        main1155 = await mainnet1155.deploy();

        latestExpTime = ((await time.latest()) + ONE_MONTH_IN_SECS)
    }) 

    it('should mint 721 freely for every user on mumbai', async () => {
        await mum721.connect(deployer).safeMint("tokenURI", latestExpTime)

        latestId = await mum721.getId("tokenURI", deployer.address, latestExpTime)
        
        assert.equal(
            await mum721.totalSupply(),
            1
        )
    })

    it('should mint 1155 freely for every user on mumbai', async () => {
        await mum1155.connect(deployer).mint("tokenURI", latestExpTime)

        latestId = await mum1155.getId("tokenURI", deployer.address, latestExpTime)
        
        assert.equal(
            await mum1155.totalSupply(latestId),
            1
        )
    })

    it('should not mint 721 with same token id', async () => {
        await expect(
            mum721.connect(deployer).safeMint("tokenURI", latestExpTime)
        ).to.be.revertedWith(
            "ERC721: token already minted"
        );
    })

    it('should not mint 721 with same token uri', async () => {
        await expect(
            mum721.connect(deployer).safeMint("tokenURI", latestExpTime + 1)
        ).to.be.revertedWith(
            "DataStorage: uri registered already"
        );
    })

    it('should check collecting fee', async () => {
        await expect(
            main1155.connect(user1).collect(
                latestId,
                "tokenURI",
                deployer.address,
                latestExpTime,
                [user1.address, user2.address], 
                [6000, 4000],
                { value: (await main1155.fee(latestId) - 100).toString() }
            )
        ).to.be.revertedWith(
            "Mainnet Farsi: insufficient fee"
        );
    })

    it('should not accept different length of address and fraction', async () => {
        await expect(
            main1155.connect(user1).collect(
                latestId,
                "tokenURI",
                deployer.address,
                latestExpTime,
                [user1.address, user2.address], 
                [10000],
                { value: await main1155.fee(latestId) }
            )
        ).to.be.revertedWith(
            "FeeManager: receivers and fractions must be the same length"
        );
    })

    it('check fee before collect 1', async () => {
        
        assert.equal(
            await main1155.fee(latestId),
            10 ** 18
        )
    })

    it('should collect 1 correctly on mainnet', async () => {
        
        await main1155.connect(user1).collect(
            latestId,
            "tokenURI",
            deployer.address,
            latestExpTime,
            [user1.address, user2.address], 
            [6000, 4000],
            { value: await main1155.fee(latestId) }
        )
    })

    it('should have correct balances after collect 1', async () => {
        
        assert.equal(
            await main1155.totalSupply(latestId),
            11
        )
        assert.equal(
            await main1155.balanceOf(deployer.address, latestId),
            10
        )
        assert.equal(
            await main1155.balanceOf(user1.address, latestId),
            1
        )
    })

    it('check fee before collect 2', async () => {
        
        assert.equal(
            await main1155.fee(latestId),
            1.275 * 10 ** 18 - 100
        )
    })

    it('should collect 2 correctly on mainnet', async () => {
        
        await main1155.connect(user2).collect(
            latestId,
            "tokenURI",
            deployer.address,
            latestExpTime,
            [user1.address, user2.address], 
            [6000, 4000],
            { value: await main1155.fee(latestId) }
        )
    })

    it('check fee before collect 3', async () => {
        
        assert.equal(
            await main1155.fee(latestId),
            1.3 * 10 ** 18 
        )
    })

    it('should have correct balances after collect 2', async () => {
        
        assert.equal(
            await main1155.totalSupply(latestId),
            12
        )
        assert.equal(
            await main1155.balanceOf(deployer.address, latestId),
            10
        )
        assert.equal(
            await main1155.balanceOf(user1.address, latestId),
            1
        )
        assert.equal(
            await main1155.balanceOf(user2.address, latestId),
            1
        )
    })

    it('should revert after expire time', async () => {

        await time.increaseTo(latestExpTime + 1);

        await expect(
            main1155.connect(user1).collect(
                latestId,
                "tokenURI",
                deployer.address,
                latestExpTime,
                [user1.address, user2.address], 
                [10000],
                { value: await main1155.fee(latestId) }
            )
        ).to.be.revertedWith(
            "Mainnet Farsi: token sale time is expired"
        );
    })


})
