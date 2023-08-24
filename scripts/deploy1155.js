const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js");
let { qhAddr, splitterAddr } = require("./utils/cont.config.js")
const { deployFee, callFee } = require("../scripts/utils/gasEstimator.js");

  async function deployFactory1155() {
    const delay = (ms) => new Promise((res) => setTimeout(res, ms));
    
    // await deployFee("Factory1155", qhAddr)

    const Factory1155 = await ethers.getContractFactory("Factory1155");
    const F1155 = await Factory1155.deploy(splitterAddr, qhAddr);
    await F1155.deployed();
    console.log("Factory1155 Contract Address:", F1155.address); 

    await delay(20000)
    await verify(F1155.address, [splitterAddr, qhAddr])
  }
    
  if (require.main === module) {
    deployFactory1155()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }