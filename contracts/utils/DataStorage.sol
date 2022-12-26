// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DataStorage {

    mapping(uint256 => Katibeh) idToToken;
    mapping(bytes32 => uint256) URIsRegistered;
    mapping(uint256 => bytes) _dappData;
    mapping(uint256 => bytes) _signatures;

    struct Katibeh {
        address creator;
        uint256 mintTime;
        uint256 initTime;
        uint256 expTime;
        string tokenURI;
        bytes data;
        uint256[] toTokenId;
        bytes32[] tags;
        address[] payableAddresses;
        uint16[] payableShares;
    }

    event NewToken(
        uint256 indexed tokenId, 
        address indexed creator, 
        bytes indexed data, 
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime
    );

    event NewReply(
        uint256 indexed tokenId,
        uint256 indexed toTokenId
    );

    event Tags(
        uint256 tokenId,
        bytes32 indexed tag1, 
        bytes32 indexed tag2, 
        bytes32 indexed tag3
    );

    function _registerURI(string calldata _uri, uint256 tokenId) internal {
        bytes32 uriHash = keccak256(abi.encodePacked(_uri));
        require(getUriId(uriHash) == 0, "DataStorage: uri registered already");
        URIsRegistered[uriHash] = tokenId;
    }

    function _emitData(
        uint256 tokenId,
        uint256[] calldata toTokenId,
        address creator,
        bytes calldata data,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime
    ) internal {
        emit NewToken(tokenId, creator, data, mintTime, initTime, expTime);
        uint256 toIdLen = toTokenId.length;
        for (uint256 i; i < toIdLen; i++){
            emit NewReply(tokenId, toTokenId[i]);
        }
    }

    function _burnData(uint256 tokenId) internal {
        Katibeh storage katibeh = idToToken[tokenId];
        delete _signatures[tokenId];
        katibeh.tokenURI = "data:application/json;base64,eyJuYW1lIjogIlRoaXMgdG9rZW4gaXMgYnVybmVkLiIsImRlc2NyaXB0aW9uIjogIlRva2VuIGlzIG5vdCBjb2xsZWN0aWJsZSBvbiB0aGlzIG5ldHdvcmsuIn0";
    }

    function _setData(
        uint256 tokenId,
        Katibeh calldata katibeh
    ) internal {
        idToToken[tokenId] = katibeh;
        emit NewToken(tokenId, katibeh.creator, katibeh.data, katibeh.mintTime, katibeh.initTime, katibeh.expTime);
        uint256 toIdLen = katibeh.toTokenId.length;
        for (uint256 i; i < toIdLen; i++){
            emit NewReply(tokenId, katibeh.toTokenId[i]);
        }
    }

    function _setDappData(uint256 tokenId, bytes calldata data) internal {
        _dappData[tokenId] = data;
    }

    function _setSignature(uint256 tokenId, bytes calldata sig) internal {
        _signatures[tokenId] = sig;
    }

    function _tokenURI(uint256 tokenId) internal view returns(string memory) {
        return idToToken[tokenId].tokenURI;
    }

    function _emitTags(uint256 tokenId, bytes32[] calldata tags) internal {
        uint256 len = tags.length;
        require(len <= 3, "DataStorage: tags length must be 3");
        bytes32 empty;
        emit Tags(
            tokenId, 
            len > 0 ? tags[0] : empty,
            len > 1 ? tags[1] : empty, 
            len > 2 ? tags[2] : empty
        );
    }

    function getUriId(bytes32 uriHash) public view returns(uint256) {
        return URIsRegistered[uriHash];
    }

    function tokenInfoBatch(uint256[] calldata tokenId) public view returns(
        Katibeh[] memory katibeh, bytes[] memory sig, bytes[] memory dappData
    ) {
        uint256 len = tokenId.length;
        katibeh = new Katibeh[](len);
        sig = new bytes[](len);
        dappData = new bytes[](len);

        for(uint256 i; i < len; i++) {
            (katibeh[i], sig[i], dappData[i]) = tokenInfo(tokenId[i]);
        }
    }

    function tokenInfo(uint256 tokenId) public view returns(
        Katibeh memory katibeh, bytes memory sig, bytes memory dappData
    ) {
        katibeh = idToToken[tokenId];
        if(block.timestamp >= katibeh.initTime) {
            sig = _signatures[tokenId];
        }
        dappData = _dappData[tokenId];
    }
}