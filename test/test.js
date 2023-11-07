/* global describe it before ethers */

const { assert, expect } = require('chai')
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { deployFee, callFee } = require("../scripts/utils/gasEstimator.js");

describe('Test', async function () {

    let zero_address
    let days = 60 * 60 *24
    let ONE_MONTH_IN_SECS
    let deployer, user1, user2, user3
    let splitter
    let QH
    let QVH
    let kat721
    let factory
    let latestId
    let latestExpTime
    let data = "0x0000000000000000000000000000000000000000000000000000000000000001"
    let nowTime

    let katibeh

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
        const accounts = await ethers.getSigners();
        [deployer, user1, user2, user3] = accounts
        let splitterCont = await hre.ethers.getContractFactory("SplitterForOwners")
        splitter = await splitterCont.deploy()
        let QVHash = await hre.ethers.getContractFactory("QVHash")
        QVH = await QVHash.deploy()
        let QHash = await hre.ethers.getContractFactory("QHash")
        QH = await QHash.deploy()
        let mumbai721 = await hre.ethers.getContractFactory("Katibeh721");
        kat721 = await mumbai721.deploy(QVH.address);
        let fac1155 = await hre.ethers.getContractFactory("Factory1155");
        factory = await fac1155.deploy(splitter.address, QH.address);
        nowTime = await time.latest();

        latestExpTime = ((await time.latest()) + ONE_MONTH_IN_SECS)

//   struct Katibeh {
//     address creator;
//     uint256 signTime;
//     uint256 initTime;
//     uint256 expTime;
//     string tokenURI;
//     bytes data;
//     uint256[] toTokenId;
//     bytes32[] tags;
//     ISplitter.Share[] owners;
//     Pricing[] pricing;
// }
// struct Pricing {
//   uint256 A;
//   int256 B;
//   int256 C;
//   int256 D;
//   uint96 royalty;
//   uint256 totalSupply;
//   uint256 discount;
//   uint256 chainId;
// }

        pricing = [[
          0,
          0,
          0,
          ethers.utils.parseEther("2"),
          100,
          10,
          5,
          0
        ]]
        katibeh = [
          user1.address,
          nowTime,
          nowTime,
          nowTime + 5 * days,
          "",
          data,
          [],
          [data, data, data],
          [[user2.address, 6000],[user3.address, 4000]], //354371 //396716
          pricing
        ]
    }) 

    it('should mint 721 freely for every user on mumbai', async () => {
        await kat721.connect(user1).safeMint(katibeh, "0x00", "0x00")

        // latestId = await kat721.getId("tokenURI", deployer.address, latestExpTime)
        
        assert.equal(
            await kat721.totalSupply(),
            1
        )
    })

    it('should collect 1 correctly on mainnet', async () => {

      // await callFee(
      //   factory, 
      //   "firstFreeCollect", 
      //   0,
      //   katibeh,
      //   0x00,
      //   0x00
      // ) //396,960 //441,484
        
      await factory.connect(user1).collect(
          0,
          katibeh,
          0x00,
          0x00,
          [],
          { value: ethers.utils.parseEther("2") }
      )
      console.log(await ethers.provider.getBalance(user1.address))
      console.log(await ethers.provider.getBalance(user2.address))
      console.log(await ethers.provider.getBalance(user3.address))
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
