const { ethers } = require("hardhat");
const { deployFee, callFee } = require("../scripts/utils/gasEstimator.js");

  async function qHash() {

    await deployFee("Factory1155", "0x7691ABD98A27E259D5c145330a2108a945B5CA42")

    await deployFee("QHash")

  }
    
  qHash();