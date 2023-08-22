const { network } = require("hardhat")

const zero_address = "0x0000000000000000000000000000000000000000"

let addrFac = zero_address
let addr721 = zero_address
let qhAddr = zero_address
let qvhAddr = zero_address

if (network.config.chainId == 80001) {
    addrFac = "0x20b224D1B8ff6A82795069271B348AEF3c7679a9"
    addr721 = "0x92c922a3aE0371D9AB9eb2598E7a45b421d019A6"
    qhAddr = "0x7597e7f54A282b605f94c56C5a4abe5cDA532039"
    qvhAddr = "0xb2678d388261ce1D4846FCCf42256cfA3bab6A46"
}

module.exports = {
    addrFac,
    addr721,
    qhAddr,
    qvhAddr
}