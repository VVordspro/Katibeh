const { ethers } = require("hardhat");
const { getContractAddress } = require('@ethersproject/address')


  async function deployTest() {

    const [deployer] = await ethers.getSigners()
    const transactionCount = await deployer.getTransactionCount()
    const futureAddress = getContractAddress({
        from: deployer.address,
        nonce: transactionCount
    })
    console.log(futureAddress)


    const Test = await ethers.getContractFactory("Test");
    const T8 = await Test.deploy();
    await T8.deployed();
    console.log("Test Contract Address:", T8.address); 

}
    
    if (require.main === module) {
      deployTest()
        .then(() => process.exit(0))
        .catch(error => {
          console.error(error)
          process.exit(1)
        })
    }