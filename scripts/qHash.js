const { ethers } = require("hardhat");
const { deployFee, callFee } = require("../scripts/utils/gasEstimator.js");

  async function qHash() {

    await deployFee("Factory1155")

    await deployFee("QHash")

  }
    
  qHash();