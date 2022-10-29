const { ethers } = require("hardhat");

  async function deployMumbai1155() {

    // simple deploy
    const Mumbai1155 = await ethers.getContractFactory("Mumbai1155");
    const MuF = await Mumbai1155.deploy();
    await MuF.deployed();
    console.log("Mumbai1155 Contract Address:", MuF.address); 

  }
    
  deployMumbai1155();