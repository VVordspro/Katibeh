// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DataStorage {

    // Structure to represent an address and its corresponding share
    struct Payee {
        address addr;
        uint16 share;
    }

    // Structure to represent the pricing details for a token
    struct Pricing {
        uint256 A;
        int256 B;
        int256 C;
        int256 D;
        uint96 royalty;
        uint256 totalSupply;
        uint256 discount;
        uint256 chainId;
    }

    // Structure to represent a token (Katibeh)
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
        Pricing[] pricing;
    }

    // Event emitted when a new token is created
    event NewToken(
        uint256 indexed tokenId, 
        address indexed creator, 
        bytes indexed data
    );

    // Event emitted when a new reply (relation between tokens) is created
    event NewReply(
        uint256 indexed tokenId,
        uint256 indexed toTokenId
    );

    // Event emitted when tags are associated with a token
    event Tags(
        uint256 tokenId,
        bytes32 indexed tag1, 
        bytes32 indexed tag2, 
        bytes32 indexed tag3
    );

    // Event emitted when a token is transferred
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    // Function to set the data for a newly created token (Katibeh)
    function _setCollectData(
        uint256 tokenId,
        Katibeh calldata katibeh
    ) internal {
        // Emit events for new token and replies
        emit NewToken(tokenId, katibeh.creator, katibeh.data);
        uint256 toIdLen = katibeh.toTokenId.length;
        for (uint256 i; i < toIdLen; ++i){
            emit NewReply(tokenId, katibeh.toTokenId[i]);
        }

        // Emit event for tags associated with the token
        uint256 len = katibeh.tags.length;
        bytes32 empty;
        emit Tags(
            tokenId, 
            len > 0 ?  katibeh.tags[0] : empty,
            len > 1 ?  katibeh.tags[1] : empty, 
            len > 2 ?  katibeh.tags[2] : empty
        );
    }
}
