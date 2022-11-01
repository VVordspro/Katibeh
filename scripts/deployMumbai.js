const { ethers } = require("hardhat");

  async function deployMumbai721() {

    // simple deploy
    const Mumbai721 = await ethers.getContractFactory("Mumbai721");
    const MuF = await Mumbai721.deploy();
    await MuF.deployed();
    console.log("Mumbai721 Contract Address:", MuF.address); 

  }
    
  deployMumbai721();