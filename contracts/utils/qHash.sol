// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library qHash {
    
    function q(
        bytes calldata sig,
        address creator
    ) internal pure returns(uint256 tokenId) {
        return uint256(keccak256(abi.encodePacked(sig, creator, "saman wilson")));
    }

}