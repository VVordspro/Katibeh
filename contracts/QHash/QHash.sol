// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./utils/qHash.sol";

contract QHash {
    using qHash for bytes;
    
    function checkHash(
        bytes calldata sig,
        uint256 tokenId
    ) external pure returns(bool) {
        return (sig.q() == tokenId);
    }
}