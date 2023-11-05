// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../splitter/PercentSplitETH.sol";

abstract contract DataStorage {

    uint256 internal constant BASIS_POINTS = 10000;

    // Structure to represent the pricing details for a token
    struct Pricing {
        uint256 A;
        int256 B;
        int256 C;
        int256 D;
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
        uint256 initTime;
        string tokenURI;
        bytes data;
        uint256[] toTokenHash;
        bytes32[] tags;
        PercentSplitETH.Share[] owners;
        Pricing[] pricing;
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
        uint256 indexed toTokenHash
    );

    // Event emitted when tags are associated with a token
    event Tags(
        uint256 tokenHash,
        bytes32 indexed tag1, 
        bytes32 indexed tag2, 
        bytes32 indexed tag3
    );

    // Event emitted when a token is transferred
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    // Function to set the data for a newly created token (Katibeh)
    function _firstEmits(
        uint256 tokenHash,
        Katibeh calldata katibeh
    ) internal {
        // Emit events for new token and replies
        emit NewToken(tokenHash, katibeh.creator, katibeh.data);
        uint256 toIdLen = katibeh.toTokenHash.length;
        for (uint256 i; i < toIdLen; ++i){
            emit NewReply(tokenHash, katibeh.toTokenHash[i]);
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
