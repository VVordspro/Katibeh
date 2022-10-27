const { ethers } = require("hardhat");

  async function deployMumbaiFarsi() {

    // simple deploy
    const MumbaiFarsi = await ethers.getContractFactory("MumbaiFarsi");
    const MuF = await MumbaiFarsi.deploy();
    await MuF.deployed();
    console.log("MumbaiFarsi Contract Address:", MuF.address); 

  }
    
  deployMumbaiFarsi();