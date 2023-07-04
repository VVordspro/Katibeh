const { ethers } = require("hardhat");
const { verify } = require("./utils/verifier.js");
let { qvhAddr } = require("./utils/cont.config.js")

  async function deployKatibeh721() {

    // simple deploy
    const Katibeh721 = await ethers.getContractFactory("Katibeh721");
    const KF = await Katibeh721.deploy(qvhAddr);
    await KF.deployed();
    console.log("Katibeh721 Contract Address:", KF.address); 

    await verify(KF.target, [qvhAddr])
  }
    
  if (require.main === module) {
    deployKatibeh721()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }