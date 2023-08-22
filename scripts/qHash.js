const { ethers } = require("hardhat");
const { deployFee, callFee } = require("../scripts/utils/gasEstimator.js");

async function qHash() {

  // await deployFee("Factory1155", "0x7691ABD98A27E259D5c145330a2108a945B5CA42")
  // Estimated gas: 4,886,980
  // Gas price (Gwei): 12.852818736
  // Gas fee (ETH): 0.06281146810645728

  // await deployFee("QHash")
  // Estimated gas: 135419
  // Gas price (Gwei): 12.852818736
  // Gas fee (ETH): 0.001740515860410384

  // Estimated gas: 4,821,412
  // Gas price (Gwei): 13.403606741
  // Gas fee (ETH): 0.064624310384338292


  const QHash = await ethers.getContractFactory("QHash");
  const QH = await QHash.deploy();
  await QH.deployed();
  console.log("QHash Contract Address:", QH.address); 

  // const QVHash = await ethers.getContractFactory("QVHash");
  // const QVH = await QVHash.deploy();
  // await QVH.deployed();
  // console.log("QVHash Contract Address:", QVH.address);

}

qHash();