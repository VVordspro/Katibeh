const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js");
let { qvhAddr } = require("./utils/cont.config.js")

  async function deployPercentSplitETH() {

    // simple deploy
    const PercentSplitETH = await ethers.getContractFactory("PercentSplitETH");
    const splitter = await PercentSplitETH.deploy();
    await splitter.deployed();
    console.log("PercentSplitETH Contract Address:", splitter.address); 

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