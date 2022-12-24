// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library VerifySig {

    function verify(
        bytes calldata _sig,
        address _signer,
        bytes32 messageHash
    ) internal pure returns(bool) {
        bytes32 ethSignMessageHash = getEthSignedMessageHash(messageHash);
        return recover(ethSignMessageHash, _sig) == _signer;
    }

// dota voroodi dige miad payableAddressList, payableShares
// dota abi.encodePacked be hash ezafe mikonam.
    function getMessageHash(
        uint256[] calldata toTokenId,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime,
        string calldata uri,
        bytes32[] calldata tags,
        address[] calldata payableAddresses,
        uint16[] calldata payableShares
    ) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            toTokenId, mintTime, initTime, expTime, uri, 
            tags[0], tags[1], tags[2], payableAddresses, payableShares
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