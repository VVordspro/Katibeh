const { ethers } = require("hardhat");

  async function deployKatibeh721() {

    // simple deploy
    const Katibeh721 = await ethers.getContractFactory("Katibeh721");
    const KF = await Katibeh721.deploy();
    await KF.deployed();
    console.log("Katibeh721 Contract Address:", KF.address); 

  }
    
  deployKatibeh721();