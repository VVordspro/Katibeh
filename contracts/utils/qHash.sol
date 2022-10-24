// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library qHash {
    
    function q(
        string calldata tokenURI,
        address creator,
        uint256 expTime
    ) internal pure returns(uint256 tokenId) {
        return uint256(keccak256(abi.encodePacked(
            tokenURI,
            creator,
            expTime,
            "saman wilson"
        )));
    }

}