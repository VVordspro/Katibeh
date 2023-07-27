const { network } = require("hardhat")

const zero_address = "0x0000000000000000000000000000000000000000"

let addrFac = zero_address
let addr721 = zero_address
let qhAddr = zero_address
let qvhAddr = zero_address

if (network.config.chainId == 80001) {
    addrFac = "0x942b2750A4E7533dbFed06F2BD866e08CA73c1C1"
    addr721 = "0xf287e59752a6B9413087176480879C2F75a52e9B"
    qhAddr = "0xD6cD7a7EcfbBb02926D7b16EeCEEbEb564a5A2ae"
    qvhAddr = "0xF01fA545800C0D4BEB4F834D3cbd983e675e45aB"
}

module.exports = {
    addrFac,
    addr721,
    qhAddr,
    qvhAddr
}