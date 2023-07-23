// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DataStorage {

    struct Payee {
        address addr;
        uint16 share;
    }

    struct Pricing {
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        uint256 royalty;
        uint256 totalSupply;
        uint256 discount;
    }
    
    struct Katibeh {
        address creator;
        uint256 signTime;
        uint256 initTime;
        uint256 expTime;
        string tokenURI;
        bytes data;
        uint256[] toTokenId;
        bytes32[] tags;
        Payee[] owners;
    }

    event NewToken(
        uint256 indexed tokenId, 
        address indexed creator, 
        bytes indexed data, 
        uint256 signTime,
        uint256 initTime,
        uint256 expTime
    );

    event NewReply(
        uint256 indexed tokenId,
        uint256 indexed toTokenId
    );

    function _setCollectData(
        uint256 tokenId,
        Katibeh calldata katibeh
    ) internal {
        emit NewToken(tokenId, katibeh.creator, katibeh.data, katibeh.signTime, katibeh.initTime, katibeh.expTime);
        uint256 toIdLen = katibeh.toTokenId.length;
        for (uint256 i; i < toIdLen; ++i){
            emit NewReply(tokenId, katibeh.toTokenId[i]);
        }
    }
}