// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DataStorage {

    mapping(string => uint256) URIsRegistered;

    mapping(uint256 => DS) idToDS;

    struct DS {
        uint256 toTokenId;
        string tokenURI;
        address creator;
        uint256 mintTime;
        uint256 initTime;
        uint256 expTime;
        bytes signature;
    }

    event NewToken(
        uint256 indexed tokenId, 
        address indexed creator, 
        uint256 indexed toTokenId, 
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime
    );

    event Tags(
        uint256 tokenId,
        string indexed tag1, 
        string indexed tag2, 
        string indexed tag3
    );

    function _registerURI(string calldata _uri, uint256 tokenId) internal {
        require(getUriId(_uri) == 0, "DataStorage: uri registered already");
        URIsRegistered[_uri] = tokenId;
    }

    function _emitData(
        uint256 tokenId,
        uint256 toTokenId,
        address creator,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime
    ) internal {
        emit NewToken(tokenId, creator, toTokenId, mintTime, initTime, expTime);
    }

    function _burnData(uint256 tokenId) internal {
        DS storage ds = idToDS[tokenId];
        delete ds.signature;
        ds.tokenURI = "data:application/json;base64,eyJuYW1lIjoiVGhpcyB0b2tlbiBpcyBidXJuZWQuIiwiZGVzY3JpcHRpb24iOiJZb3UgbWF5IGZpbmQgdGhpcyB0b2tlbiBvbiBvdGhlciBuZXR3b3Jrcy4iLCJpbWFnZSI6ImlwZnM6Ly9RbWNjWW5BSHV6c3NBZm0yVUI0QXd3UEp2RFpKM0RmNkhHM3lQUkZ0Qm1pZTYxIn0=";
    }

    function _setData(
        uint256 tokenId,
        uint256 toTokenId,
        string memory tokenURI,
        address creator,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime,
        bytes calldata sig
    ) internal {
        idToDS[tokenId] = DS(toTokenId, tokenURI, creator, mintTime, initTime, expTime, sig);
        emit NewToken(tokenId, creator, toTokenId, mintTime, initTime, expTime);
    }

    function _tokenURI(uint256 tokenId) internal view returns(string memory) {
        return idToDS[tokenId].tokenURI;
    }

    function _emitTags(uint256 tokenId, string[] calldata tags) internal {
        require(tags.length == 3, "DataStorage: tags length must be 3");
        emit Tags(tokenId, tags[0], tags[1], tags[2]);
    }

    function getUriId(string calldata _uri) public view returns(uint256) {
        return URIsRegistered[_uri];
    }

    function getData(uint256 tokenId) public view returns(DS memory) {
        return idToDS[tokenId];
    }
}