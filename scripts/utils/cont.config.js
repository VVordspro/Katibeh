const { network } = require("hardhat")

const zero_address = "0x0000000000000000000000000000000000000000"

let addrFac = zero_address
let addr721 = zero_address
let qhAddr = zero_address
let qvhAddr = zero_address
let splitterAddr = zero_address

if (network.config.chainId == 80001) {
    splitterAddr = "0xdDEd6Ae675559C8612eE19a65742233771D1D792"
    addrFac = "0x20b224D1B8ff6A82795069271B348AEF3c7679a9"
    addr721 = "0xcacF36e3c8a2E3763E3E53e98d2801bd839E3D2b"
    qhAddr = "0x7597e7f54A282b605f94c56C5a4abe5cDA532039"
    qvhAddr = "0x61E4359D669d6B9842f14Ca3209853Cc8DdCC335"
} else if (network.config.chainId == 137) {
    splitterAddr = ""
    addrFac = ""
    addr721 = ""
    qhAddr = ""
    qvhAddr = ""
} else if (network.config.chainId == 1) {
    splitterAddr = "0xd5C2bd6777250188B34D77C82e46838b602B06A3"
}

module.exports = {
    addrFac,
    addr721,
    qhAddr,
    qvhAddr
}