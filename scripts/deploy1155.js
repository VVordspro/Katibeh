const { ethers } = require("hardhat");

  async function deployFactory1155() {

    const Factory1155 = await ethers.getContractFactory("Factory1155");
    const F1155 = await Factory1155.deploy();
    await F1155.deployed();
    console.log("Factory1155 Contract Address:", F1155.address); 
  }
    
  if (require.main === module) {
    deployFactory1155()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }