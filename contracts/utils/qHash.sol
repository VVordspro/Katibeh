// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library qHash {
    
    function q(
        string calldata tokenURI, 
        uint256 mintTime
    ) internal pure returns(uint256 tokenId) {
        return uint256(keccak256(abi.encodePacked(
            tokenURI,
            mintTime,
            "saman wilson"
        )));
    }

}