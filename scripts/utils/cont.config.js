const { network } = require("hardhat")

const zero_address = "0x0000000000000000000000000000000000000000"

let addrFac = zero_address
let addr721 = zero_address
let qhAddr = zero_address
let qvhAddr = zero_address

if (network.config.chainId == 80001) {
    addrFac = "0x942b2750A4E7533dbFed06F2BD866e08CA73c1C1"
    addr721 = "0xe73db8042D0CA27a5F970216D30CfFB7257de735"
    qhAddr = "0xD6cD7a7EcfbBb02926D7b16EeCEEbEb564a5A2ae"
    qvhAddr = "0x5Fc017BF313F92656A96EeFb6875C50D731bf6e6"
}

module.exports = {
    addrFac,
    addr721,
    qhAddr,
    qvhAddr
}