// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../splitter/PercentSplitETH.sol";

abstract contract DataStorage {

    uint256 constant basisPoint = 32767;

    // Structure to represent the pricing details for a token
    struct Pricing {
        int256 A;
        int256 B;
        uint96 totalSupply;
        uint96 expTime;
        uint64 discount;
        uint96 initTime;
        uint96 royalty;
        uint256 chainId;
    }

    // Structure to represent a token (Katibeh)
    struct Katibeh {
        address creator;
        uint96 signTime;
        string tokenURI;
        bytes data;
        ToTokenHash[] toTokenHash;
        bytes32[] tags;
        SplitterForOwners.Share[] owners;
        Pricing[] pricing;
    }

    struct ToTokenHash {
        uint256 tokenHash;
        int256 value;
    }

    struct Collection{
        address addr;
        uint96 tokenId;
    }

    struct ReplyCollection{
        address addr;
        uint80 tokenId;
        int16 value;
    }

    // Event emitted when a new token is created
    event NewToken(
        uint256 indexed tokenHash, 
        address indexed creator, 
        bytes indexed data
    );

    // Event emitted when a new reply (relation between tokens) is created
    event NewReply(
        uint256 indexed tokenHash,
        uint256 indexed toTokenHash,
        int256 value
    );

    // Event emitted when tags are associated with a token
    event Tags(
        uint256 tokenHash,
        bytes32 indexed tag1, 
        bytes32 indexed tag2, 
        bytes32 indexed tag3
    );

    // Function to set the data for a newly created token (Katibeh)
    function _firstEmits(
        uint256 tokenHash,
        Katibeh calldata katibeh
    ) internal {
        // Emit events for new token and replies
        emit NewToken(tokenHash, katibeh.creator, katibeh.data);
        uint256 toIdLen = katibeh.toTokenHash.length;
        for (uint256 i; i < toIdLen; ++i){
            emit NewReply(tokenHash, katibeh.toTokenHash[i].tokenHash, katibeh.toTokenHash[i].value);
        }

        // Emit event for tags associated with the token
        uint256 len = katibeh.tags.length;
        bytes32 empty;
        emit Tags(
            tokenHash, 
            len > 0 ?  katibeh.tags[0] : empty,
            len > 1 ?  katibeh.tags[1] : empty, 
            len > 2 ?  katibeh.tags[2] : empty
        );
    }
}
