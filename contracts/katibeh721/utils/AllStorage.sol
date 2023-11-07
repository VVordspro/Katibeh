// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../storage/DataStorage.sol";

/**
 * @title AllStorage Contract
 * @dev An abstract contract that provides storage functionality for the Katibeh721 contract.
 */
abstract contract AllStorage is DataStorage {

    mapping(uint256 => Katibeh) idToToken; // Mapping from token ID to Katibeh struct
    mapping(bytes32 => uint256) URIsRegistered; // Mapping from URI hash to token ID
    mapping(uint256 => bytes) _dappData; // Mapping from token ID to Dapp data
    mapping(uint256 => bytes) _signatures; // Mapping from token ID to token signature
    mapping(uint256 => uint256) public tokenMintTime; // Mapping from token ID to token mint time

    /**
     * @dev Internal function to register a token URI hash.
     * @param _uri The token URI to be registered.
     * @param tokenId The ID of the token to associate with the URI hash.
     */
    function _registerURI(string calldata _uri, uint256 tokenId) internal {
        bytes32 uriHash = keccak256(abi.encodePacked(_uri));
        require(getUriId(uriHash) == 0, "DataStorage: URI registered already");
        URIsRegistered[uriHash] = tokenId;
    }

    /**
     * @dev Internal function to clear data when burning a token.
     * @param tokenId The ID of the token to be burned.
     */
    function _burnData(uint256 tokenId) internal {
        Katibeh storage katibeh = idToToken[tokenId];
        delete _signatures[tokenId];
        katibeh.tokenURI = "data:application/json;base64,eyJuYW1lIjogIlRoaXMgdG9rZW4gaXMgYnVybmVkLiIsImRlc2NyaXB0aW9uIjogIlRva2VuIGlzIG5vdCBjb2xsZWN0aWJsZSBvbiB0aGlzIG5ldHdvcmsuIn0";
    }

    /**
     * @dev Internal function to set mint data for a new token.
     * @param tokenId The ID of the newly minted token.
     * @param katibeh The Katibeh struct associated with the token.
     */
    function _setMintData(uint256 tokenId, Katibeh calldata katibeh) internal {
        idToToken[tokenId] = katibeh;
        emit NewToken(tokenId, katibeh.creator, katibeh.data);
        uint256 toIdLen = katibeh.toTokenHash.length;
        for (uint256 i; i < toIdLen; ++i){
            emit NewReply(tokenId, katibeh.toTokenHash[i]);
        }
    }

    /**
     * @dev Internal function to set Dapp data for a token.
     * @param tokenId The ID of the token to set the Dapp data for.
     * @param data The Dapp data to be associated with the token.
     */
    function _setDappData(uint256 tokenId, bytes calldata data) internal {
        _dappData[tokenId] = data;
    }

    /**
     * @dev Internal function to set the signature for a token.
     * @param tokenId The ID of the token to set the signature for.
     * @param sig The signature to be associated with the token.
     */
    function _setSignature(uint256 tokenId, bytes calldata sig) internal {
        _signatures[tokenId] = sig;
    }

    /**
     * @dev Internal function to retrieve the token URI for a token.
     * @param tokenId The ID of the token to retrieve the URI for.
     * @return The URI associated with the token.
     */
    function _tokenURI(uint256 tokenId) internal view returns(string memory) {
        return idToToken[tokenId].tokenURI;
    }

    /**
     * @dev Internal function to emit token tags.
     * @param tokenId The ID of the token associated with the tags.
     * @param tags The array of tags to be emitted.
     */
    function _emitTags(uint256 tokenId, bytes32[] calldata tags) internal {
        uint256 len = tags.length;
        require(len <= 3, "DataStorage: Tags length must be less than or equal to 3");
        bytes32 empty;
        if(len > 2) {
            require(tags[2][0] != 0x23, "DataStorage: not acceptable character # in tag3");
        } if(len > 1) {
            require(tags[1][0] != 0x23, "DataStorage: not acceptable character # in tag2");
        }
        emit Tags(
            tokenId, 
            len > 0 ? tags[0] : empty,
            len > 1 ? tags[1] : empty, 
            len > 2 ? tags[2] : empty
        );
    }

    /**
     * @dev Get the ID of a registered URI hash.
     * @param uriHash The hash of the URI to query.
     * @return The ID of the token associated with the URI hash.
     */
    function getUriId(bytes32 uriHash) public view returns(uint256) {
        return URIsRegistered[uriHash];
    }

    /**
     * @dev Get information for an array of tokens.
     * @param tokenId An array of token IDs to query.
     * @return katibeh An array of Katibeh structs representing the tokens.
     * @return mintTime An array of mint times for the tokens.
     * @return sig An array of signatures for the tokens.
     * @return dappData An array of Dapp data for the tokens.
     */
    function tokensInfoBatch(uint256[] calldata tokenId) public view returns(
        Katibeh[] memory katibeh, uint256[] memory mintTime, bytes[] memory sig, bytes[] memory dappData
    ) {
        uint256 len = tokenId.length;
        katibeh = new Katibeh[](len);
        mintTime = new uint256[](len);
        sig = new bytes[](len);
        dappData = new bytes[](len);

        for(uint256 i; i < len; ++i) {
            (katibeh[i], mintTime[i], sig[i], dappData[i]) = tokenInfo(tokenId[i]);
        }
    }

    /**
     * @dev Get information for a token.
     * @param tokenId The ID of the token to query.
     * @return katibeh The Katibeh struct representing the token.
     * @return mintTime The mint time for the token.
     * @return sig The signature for the token (if available).
     * @return dappData The Dapp data for the token (if available).
     */
    function tokenInfo(uint256 tokenId) public view returns(
        Katibeh memory katibeh, uint256 mintTime, bytes memory sig, bytes memory dappData
    ) {
        katibeh = idToToken[tokenId];
        mintTime = tokenMintTime[tokenId];
        if(block.timestamp >= katibeh.initTime) {
            sig = _signatures[tokenId];
        }
        dappData = _dappData[tokenId];
    }

    /**
     * @dev Get the shareholders for a token.
     * @param tokenId The ID of the token to query.
     * @return _owners_ An array of ISplitter.Share structs representing the token shareholders.
     */
    function tokenShareholders(uint256 tokenId) public view returns(SplitterForOwners.Share[] memory _owners_) {
        Katibeh memory token = idToToken[tokenId];
        if(token.owners.length == 0) {
            _owners_ = new SplitterForOwners.Share[](1);
            _owners_[0] = SplitterForOwners.Share(payable(token.creator), 1);
        } else {
            return token.owners;
        }
    }
}
