// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../storage/DataStorage.sol";

abstract contract AllStorage is DataStorage{

    mapping(uint256 => Katibeh) idToToken;
    mapping(bytes32 => uint256) URIsRegistered;
    mapping(uint256 => bytes) _dappData;
    mapping(uint256 => bytes) _signatures;
    mapping(uint256 => uint256) public tokenMintTime;

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

    function _burnData(uint256 tokenId) internal {
        Katibeh storage katibeh = idToToken[tokenId];
        delete _signatures[tokenId];
        katibeh.tokenURI = "data:application/json;base64,eyJuYW1lIjogIlRoaXMgdG9rZW4gaXMgYnVybmVkLiIsImRlc2NyaXB0aW9uIjogIlRva2VuIGlzIG5vdCBjb2xsZWN0aWJsZSBvbiB0aGlzIG5ldHdvcmsuIn0";
    }

    function _setMintData(
        uint256 tokenId,
        Katibeh calldata katibeh
    ) internal {
        idToToken[tokenId] = katibeh;
        emit NewToken(tokenId, katibeh.creator, katibeh.data, katibeh.signTime, katibeh.initTime, katibeh.expTime);
        uint256 toIdLen = katibeh.toTokenId.length;
        for (uint256 i; i < toIdLen; ++i){
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
        require(len <= 3, "DataStorage: tags length must be less than or equal to 3");
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

    function tokenShareholders(uint256 tokenId) public view returns(Payee[] memory _owners_) {
        Katibeh memory token = idToToken[tokenId];
        if(token.owners.length == 0) {
            _owners_ = new Payee[](1);
            _owners_[0] = Payee(token.creator, 1);
        } else {
            return token.owners;
        }
    }
}