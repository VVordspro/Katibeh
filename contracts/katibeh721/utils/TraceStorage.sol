// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract TraceStorage {
    
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for *;


// id details -----------------------------------------------------------

    EnumerableMap.UintToUintMap idDetails;

    function numberOfTokensTraceable() public view returns(uint256 count) {
        return idDetails.length();
    }

    function tokensByIndexTraceableBatch(uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            id[i] = tokenByIndexTraceable(index[i]);
        }
    }

    function tokenByIndexTraceable(uint256 index) public view returns(uint256 id) {
        (id,) = idDetails.at(index);
    }

    function traceTokenById(uint256 id) public view returns(
        uint256 numberOfPreviousIds,
        uint256 numberOfNextIds,
        uint256 previousId,
        uint256 nextId
    ) {
        numberOfPreviousIds = idDetails.get(id);
        numberOfNextIds = idDetails.length() - numberOfPreviousIds - 1;
        if(numberOfPreviousIds != 0) (previousId,) = idDetails.at(numberOfPreviousIds-1);
        if(numberOfNextIds != 0) (nextId,) = idDetails.at(numberOfPreviousIds+1);
    }

    function _setTokenTraceable(uint256 id) internal {
        idDetails.set(id, idDetails.length());
    }


// creator tokens -----------------------------------------------------------

    mapping(address => EnumerableMap.UintToUintMap) creatorTokens;

    function numberOfTokensOfCreatorBatch(address[] calldata creator) public view returns(uint256[] memory count) {
        uint256 len = creator.length;
        count = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            count[i] = numberOfTokensOfCreator(creator[i]);
        }
    }

    function numberOfTokensOfCreator(address creator) public view returns(uint256) {
        return creatorTokens[creator].length();
    }

    function tokensOfCreatorByIndexBatch(address creator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;

        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = tokenOfCreatorByIndex(creator, index[i]);
        }
    }

    function tokenOfCreatorByIndex(address creator, uint256 index) public view returns(uint256 id) {
        (id,) = creatorTokens[creator].at(index);
    }

    function tokensOfCreator(address creator) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage creatorIds = creatorTokens[creator];
        uint256 len = creatorIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = creatorIds.at(i);
        }
    }

    function traceTokenByCreator(address creator, uint256 id) public view returns(
        uint256 numberOfPreviousIds,
        uint256 numberOfNextIds,
        uint256 previousId,
        uint256 nextId
    ) {
        EnumerableMap.UintToUintMap storage creatorIds = creatorTokens[creator];

        numberOfPreviousIds = creatorIds.get(id);
        numberOfNextIds = creatorIds.length() - numberOfPreviousIds - 1;
        if(numberOfPreviousIds != 0) (previousId,) = creatorIds.at(numberOfPreviousIds-1);
        if(numberOfNextIds != 0) (nextId,) = creatorIds.at(numberOfPreviousIds+1);
    }

    function _setCreatorToken(address creator, uint256 id) internal {
        creatorTokens[creator].set(id, creatorTokens[creator].length());
    }


// creators ------------------------------------------------------------------

    EnumerableSet.AddressSet creators;

    function numberOfCreators() public view returns(uint256) {
        return creators.length();
    }

    function creatorsByIndexBatch(uint256[] calldata index) public view returns(address[] memory creator) {
        uint256 len = index.length;
        creator = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            creator[i] = creatorByIndex(index[i]);
        }
    }

    function creatorByIndex(uint256 index) public view returns(address creator) {
        creator = creators.at(index);
    }

    function creatorAddresses() public view returns(address[] memory creator){
        return creators.values();
    }

    function _addCreator(address creator) internal {
        creators.add(creator);
    }

// Token replies -----------------------------------------------------------

    mapping(uint256 => EnumerableSet.UintSet) tokenReplyIds;

    function numberOfTokenRepliesBatch(uint256[] calldata tokenId) public view returns(uint256[] memory count) {
        uint256 len = tokenId.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = numberOfTokenReplies(tokenId[i]);
        }
    }

    function numberOfTokenReplies(uint256 tokenId) public view returns(uint256) {
        return tokenReplyIds[tokenId].length();
    }

    function tokenRepliesByIndexBatch(uint256 tokenId, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = tokenReplyByIndex(tokenId, index[i]);
        }
    }

    function tokenReplyByIndex(uint256 tokenId, uint256 index) public view returns(uint256 id) {
        id = tokenReplyIds[tokenId].at(index);
    }

    function tokenReplies(uint256 tokenId) public view returns(uint256[] memory ids) {
        return tokenReplyIds[tokenId].values();
    }

    function _setTokenReply(uint256 id, uint256 tokenId) internal {
        tokenReplyIds[tokenId].add(id);
    }


// Creator replies -----------------------------------------------------------
    mapping(address => EnumerableSet.UintSet) creatorReplies;

    function numberOfRepliesToCreatorBatch(address[] calldata toCreator) public view returns(uint256[] memory count) {
        uint256 len = toCreator.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = numberOfRepliesToCreator(toCreator[i]);
        }
    }

    function numberOfRepliesToCreator(address toCreator) public view returns(uint256) {
        return creatorReplies[toCreator].length();
    }

    function repliesToCreatorByIndexBatch(address toCreator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);
        for (uint256 i; i < len; i++) {
            id[i] = repliesToCreatorByIndex(toCreator, index[i]);
        }
    }

    function repliesToCreatorByIndex(address toCreator, uint256 index) public view returns(uint256 id) {
        id = creatorReplies[toCreator].at(index);
    }

    function repliesToCreator(address toCreator) public view returns(uint256[] memory ids) {
        return creatorReplies[toCreator].values();
    }

    function _setCreatorReply(address toCreator, uint256 id) internal {
        creatorReplies[toCreator].add(id);
    }

// tag details -----------------------------------------------------------

    mapping(bytes32 => EnumerableMap.UintToUintMap) tagsDetails;

    function numberOfTokensByTagBatch(bytes32[] calldata tag) public view returns(uint256[] memory count) {
        uint256 len = tag.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = numberOfTokensByTag(tag[i]);
        }
    }

    function numberOfTokensByTag(bytes32 tag) public view returns(uint256) {
        return tagsDetails[tag].length();
    }

    function tokensOfTagByIndexBatch(bytes32 tag, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = tokenOfTagByIndex(tag, index[i]);
        }
    }

    function tokenOfTagByIndex(bytes32 tag, uint256 index) public view returns(uint256 id) {
        (id,) = tagsDetails[tag].at(index);
    }

    function tokensOfTag(bytes32 tag) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage tagIds = tagsDetails[tag];
        uint256 len = tagIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = tagIds.at(i);
        }
    }

    function traceTokenByTag(bytes32 tag, uint256 id) public view returns(
        uint256 numberOfPreviousIds,
        uint256 numberOfNextIds,
        uint256 previousId,
        uint256 nextId
    ) {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tag];

        numberOfPreviousIds = tagDetails.get(id);
        numberOfNextIds = tagDetails.length() - numberOfPreviousIds - 1;
        if(numberOfPreviousIds != 0) (previousId,) = tagDetails.at(numberOfPreviousIds-1);
        if(numberOfNextIds != 0) (nextId,) = tagDetails.at(numberOfPreviousIds+1);
    }

    function _setTagDetails(uint256 id, bytes32 tag) private {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tag];
        if(!tagDetails.contains(id)){
            tagDetails.set(id, tagsDetails[tag].length());
        }
    }

    function _registerTags(uint256 id, bytes32[] calldata tags) internal {
        uint256 len = tags.length;
        if(len > 0) {
            _setTagDetails(id, tags[0]);
            if (len > 1) {
                _setTagDetails(id, tags[1]);
                _setTagDetails(id, keccak256(abi.encodePacked(tags[0], tags[1])));
                if(len > 2) {
                    _setTagDetails(id, tags[2]);
                    _setTagDetails(id, keccak256(abi.encodePacked(tags[1], tags[2])));
                    _setTagDetails(id, keccak256(abi.encodePacked(tags[0], tags[1], tags[2])));
                }
            }
        }
    }
}