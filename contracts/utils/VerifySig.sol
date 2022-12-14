// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library VerifySig {

    function verify(
        bytes memory _sig,
        address _signer,
        string memory toTokenId,
        string memory initTime,
        string memory expTime,
        string memory uri,
        string[] memory tags
    ) internal pure returns(bool) {
        bytes32 messageHash = getMessageHash(toTokenId, initTime, expTime, uri, tags);
        bytes32 ethSignMessageHash = getEthSignedMessageHash(messageHash);

        return recover(ethSignMessageHash, _sig) == _signer;
    }

    function getMessageHash(
        string memory toTokenId,
        string memory initTime,
        string memory expTime,
        string memory uri,
        string[] memory tags
    ) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            "I verify a token reply to ", toTokenId,
            " to be minted on 'Katibeh' from: ", initTime, " until: ", expTime,
            " on these categories: ", tags[1], tags[2], tags[3],
            " with the tokenURI: ",  uri
        ));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _messageHash
        ));
    }

    function recover(
        bytes32 _ethSignedMessageHash,
        bytes memory _sig
    ) private pure returns(address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig) private pure 
        returns(bytes32 r, bytes32 s, uint8 v) 
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r:= mload(add(_sig, 32))
            s:= mload(add(_sig, 64))
            v:= byte(0, mload(add(_sig, 96)))
        }
    }
}