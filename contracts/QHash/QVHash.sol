// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./utils/qHash.sol";
import "./utils/VerifySig.sol";
import "../katibeh721/utils/DataStorage.sol";

contract QVHash {
    using qHash for bytes;
    using VerifySig for bytes;

    function hash(
        DataStorage.Katibeh calldata katibeh,
        bytes calldata sig
    ) public view returns(uint256) {
        require(
            sig.verify(
                katibeh.creator,
                getHash(katibeh)
            ),
            "Katibeh721: Invalid signature"
        );
        return sig.q();
    }

    function getHash(DataStorage.Katibeh calldata katibeh) public view returns(bytes32) {
        require(
            block.timestamp >= katibeh.signTime - 1 hours &&
            block.timestamp < katibeh.signTime + 1 hours,
            "Katibeh721: more than 1 hours sign time difference."
        );
        require(
            katibeh.signTime <= katibeh.initTime &&
            katibeh.initTime <= katibeh.expTime,
            "Katibeh721: sign time must be less than init time & init time must be less than expire time."
        );
        return keccak256(abi.encode(katibeh));
    }
}