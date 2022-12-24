// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DataStorage {

    mapping(string => uint256) URIsRegistered;

    mapping(uint256 => DS) idToDS;

    struct DS {
        address creator;
        uint256[] toTokenId;
        uint256 mintTime;
        uint256 initTime;
        uint256 expTime;
        string tokenURI;
        bytes32[] tags;
        address[] payableAddresses;
        uint16[] payableShares;
        bytes sig;
        bytes dappData;
    }

    event NewToken(
        uint256 indexed tokenId, 
        address indexed creator, 
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
        require(getUriId(_uri) == 0, "DataStorage: uri registered already");
        URIsRegistered[_uri] = tokenId;
    }

    function _emitData(
        uint256 tokenId,
        uint256[] calldata toTokenId,
        address creator,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime
    ) internal {
        emit NewToken(tokenId, creator, mintTime, initTime, expTime);
        uint256 toIdLen = toTokenId.length;
        for (uint256 i; i < toIdLen; i++){
            emit NewReply(tokenId, toTokenId[i]);
        }
    }

    function _burnData(uint256 tokenId) internal {
        DS storage ds = idToDS[tokenId];
        delete ds.sig;
        ds.tokenURI = "data:application/json;base64,eyJuYW1lIjoiVGhpcyB0b2tlbiBpcyBidXJuZWQuIiwiZGVzY3JpcHRpb24iOiJZb3UgbWF5IGZpbmQgdGhpcyB0b2tlbiBvbiBvdGhlciBuZXR3b3Jrcy4iLCJpbWFnZSI6ImlwZnM6Ly9RbWNjWW5BSHV6c3NBZm0yVUI0QXd3UEp2RFpKM0RmNkhHM3lQUkZ0Qm1pZTYxIn0=";
    }

    function _setData(
        uint256 tokenId,
        uint256[] calldata toTokenId,
        string memory tokenURI,
        address creator,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime,
        bytes32[] calldata tags,
        address[] calldata payableAddresses,
        uint16[] calldata payableShares,
        bytes calldata sig,
        bytes calldata dappData
    ) internal {
        // require(
        //     sig.verify(
        //         creator,
        //         getMessageHash(
        //             toTokenId,
        //             mintTime,
        //             initTime,
        //             expTime,
        //             uri,
        //             tags,
        //             payableAddresses,
        //             payableShares
        //         )
        //     ),
        //     "Katibeh721: Invalid signature"
        // );
        idToDS[tokenId] = DS(creator, toTokenId, mintTime, initTime, expTime, tokenURI, tags, payableAddresses, payableShares, sig, dappData);
        emit NewToken(tokenId, creator, mintTime, initTime, expTime);
        uint256 toIdLen = toTokenId.length;
        for (uint256 i; i < toIdLen; i++){
            emit NewReply(tokenId, toTokenId[i]);
        }
    }

    function _tokenURI(uint256 tokenId) internal view returns(string memory) {
        return idToDS[tokenId].tokenURI;
    }

    function _emitTags(uint256 tokenId, bytes32[] calldata tags) internal {
        require(tags.length == 3, "DataStorage: tags length must be 3");
        emit Tags(tokenId, tags[0], tags[1], tags[2]);
    }

    function getUriId(string calldata _uri) public view returns(uint256) {
        return URIsRegistered[_uri];
    }

    function getData(uint256 tokenId) public view returns(DS memory ds) {
        ds = idToDS[tokenId];
        if(block.timestamp <= ds.initTime) {
            delete ds.sig;
        }
    }
}