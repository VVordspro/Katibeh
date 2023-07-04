const { network } = require("hardhat")

const zero_address = "0x0000000000000000000000000000000000000000"

let addrFac = zero_address
let addr721 = zero_address
let qhAddr = zero_address
let qvhAddr = zero_address

if (network.config.chainId == 80001) {
    addrFac = "0xb481c95Cb8334C2B1f28E6e993198aC40E6c4926"
    addr721 = "0xa644Fa8D3d4681f5BAe249b793609946Ad9df492"
    qhAddr = "0xD6cD7a7EcfbBb02926D7b16EeCEEbEb564a5A2ae"
    qvhAddr = "0x5Fc017BF313F92656A96EeFb6875C50D731bf6e6"
}

module.exports = {
    addrFac,
    addr721,
    qhAddr,
    qvhAddr
}