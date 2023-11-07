const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js");
let { qvhAddr } = require("./utils/cont.config.js")

  async function deployPercentSplitETH() {

    // simple deploy
    const SplitterForOwners = await ethers.getContractFactory("SplitterForOwners");
    const splitter = await SplitterForOwners.deploy();
    await splitter.deployed();
    console.log("SplitterForOwners Contract Address:", splitter.address); 

    await verify(splitter.address, [])
  }
    
  if (require.main === module) {
    deployPercentSplitETH()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }