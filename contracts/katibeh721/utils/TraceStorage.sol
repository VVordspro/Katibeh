// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title TraceStorage
 * @dev An abstract contract that provides traceability and token storage functionalities.
 *      It includes features to store and manage token traces, creator tokens, creators, token replies, and tags.
 */
abstract contract TraceStorage {
    
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for *;

// id details -----------------------------------------------------------

    EnumerableMap.UintToUintMap idDetails;

    /**
     * @dev Get the number of tokens that have traces stored.
     * @return count The number of tokens with traces stored.
     */
    function numberOfTokensTraceable() public view returns(uint256 count) {
        return idDetails.length();
    }

    /**
     * @dev Get an array of traceable tokens by their indices.
     * @param index An array of indices.
     * @return id An array of token IDs.
     */
    function tokensByIndexTraceableBatch(uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for(uint256 i = 0; i < len; ++i) {
            id[i] = tokenByIndexTraceable(index[i]);
        }
    }

    /**
     * @dev Get the token ID at a specific index.
     * @param index The index of the token.
     * @return id The token ID at the given index.
     */
    function tokenByIndexTraceable(uint256 index) public view returns(uint256 id) {
        (id,) = idDetails.at(index);
    }

    /**
     * @dev Get the trace information for a given token ID.
     * @param id The ID of the token to trace.
     * @return numberOfPreviousIds The number of tokens traced before this token.
     * @return numberOfNextIds The number of tokens traced after this token.
     * @return previousId The ID of the token traced before this token.
     * @return nextId The ID of the token traced after this token.
     */
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

    /**
     * @dev Internal function to set a token as traceable.
     * @param id The ID of the token to set as traceable.
     */
    function _setTokenTraceable(uint256 id) internal {
        idDetails.set(id, idDetails.length());
    }

// creator tokens -----------------------------------------------------------

    mapping(address => EnumerableMap.UintToUintMap) creatorTokens;

    /**
     * @dev Get the number of tokens owned by a specific creator.
     * @param creator The address of the creator.
     * @return count The number of tokens owned by the creator.
     */
    function numberOfTokensOfCreatorBatch(address[] calldata creator) public view returns(uint256[] memory count) {
        uint256 len = creator.length;
        count = new uint256[](len);

        for (uint256 i = 0; i < len; ++i) {
            count[i] = numberOfTokensOfCreator(creator[i]);
        }
    }

    /**
     * @dev Get the number of tokens owned by a specific creator.
     * @param creator The address of the creator.
     * @return The number of tokens owned by the creator.
     */
    function numberOfTokensOfCreator(address creator) public view returns(uint256) {
        return creatorTokens[creator].length();
    }

    /**
     * @dev Get an array of tokens owned by a specific creator by their indices.
     * @param creator The address of the creator.
     * @param index An array of indices.
     * @return id An array of token IDs owned by the creator.
     */
    function tokensOfCreatorByIndexBatch(address creator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;

        id = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            id[i] = tokenOfCreatorByIndex(creator, index[i]);
        }
    }

    /**
     * @dev Get the token ID owned by a specific creator at a specific index.
     * @param creator The address of the creator.
     * @param index The index of the token.
     * @return id The token ID owned by the creator at the given index.
     */
    function tokenOfCreatorByIndex(address creator, uint256 index) public view returns(uint256 id) {
        (id,) = creatorTokens[creator].at(index);
    }

    /**
     * @dev Get an array of all token IDs owned by a specific creator.
     * @param creator The address of the creator.
     * @return ids An array of token IDs owned by the creator.
     */
    function tokensOfCreator(address creator) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage creatorIds = creatorTokens[creator];
        uint256 len = creatorIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; ++i) {
            (ids[i],) = creatorIds.at(i);
        }
    }

    /**
     * @dev Get the trace information for a token owned by a specific creator.
     * @param creator The address of the creator.
     * @param id The ID of the token to trace.
     * @return numberOfPreviousIds The number of tokens traced before this token.
     * @return numberOfNextIds The number of tokens traced after this token.
     * @return previousId The ID of the token traced before this token.
     * @return nextId The ID of the token traced after this token.
     */
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

    /**
     * @dev Internal function to set a token as owned by a specific creator.
     * @param creator The address of the creator.
     * @param id The ID of the token to set as owned by the creator.
     */
    function _setCreatorToken(address creator, uint256 id) internal {
        creatorTokens[creator].set(id, creatorTokens[creator].length());
    }

// creators ------------------------------------------------------------------

    EnumerableSet.AddressSet creators;

    /**
     * @dev Get the number of registered creators.
     * @return The number of registered creators.
     */
    function numberOfCreators() public view returns(uint256) {
        return creators.length();
    }

    /**
     * @dev Get an array of creators by their indices.
     * @param index An array of indices.
     * @return creator An array of creator addresses.
     */
    function creatorsByIndexBatch(uint256[] calldata index) public view returns(address[] memory creator) {
        uint256 len = index.length;
        creator = new address[](len);

        for (uint256 i = 0; i < len; ++i) {
            creator[i] = creatorByIndex(index[i]);
        }
    }

    /**
     * @dev Get the creator address at a specific index.
     * @param index The index of the creator.
     * @return creator The creator address at the given index.
     */
    function creatorByIndex(uint256 index) public view returns(address creator) {
        creator = creators.at(index);
    }

    /**
     * @dev Get an array of all registered creator addresses.
     * @return creator An array of creator addresses.
     */
    function creatorAddresses() public view returns(address[] memory creator){
        return creators.values();
    }

    /**
     * @dev Internal function to add a creator to the registered list.
     * @param creator The address of the creator to add.
     */
    function _addCreator(address creator) internal {
        creators.add(creator);
    }

// Token replies -----------------------------------------------------------

    mapping(uint256 => EnumerableSet.UintSet) tokenReplyIds;

    /**
     * @dev Get the number of token replies for an array of token IDs.
     * @param tokenId An array of token IDs.
     * @return count An array with the number of replies for each token ID.
     */
    function numberOfTokenRepliesBatch(uint256[] calldata tokenId) public view returns(uint256[] memory count) {
        uint256 len = tokenId.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; ++i) {
            count[i] = numberOfTokenReplies(tokenId[i]);
        }
    }

    /**
     * @dev Get the number of token replies for a specific token ID.
     * @param tokenId The token ID to query.
     * @return The number of token replies for the given token ID.
     */
    function numberOfTokenReplies(uint256 tokenId) public view returns(uint256) {
        return tokenReplyIds[tokenId].length();
    }

    /**
     * @dev Get an array of token replies for a specific token ID by their indices.
     * @param tokenId The token ID to query.
     * @param index An array of indices.
     * @return id An array of token IDs representing the replies.
     */
    function tokenRepliesByIndexBatch(uint256 tokenId, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            id[i] = tokenReplyByIndex(tokenId, index[i]);
        }
    }

    /**
     * @dev Get a token reply for a specific token ID at a specific index.
     * @param tokenId The token ID to query.
     * @param index The index of the token reply.
     * @return id The token ID representing the reply at the given index.
     */
    function tokenReplyByIndex(uint256 tokenId, uint256 index) public view returns(uint256 id) {
        id = tokenReplyIds[tokenId].at(index);
    }

    /**
     * @dev Get an array of all token replies for a specific token ID.
     * @param tokenId The token ID to query.
     * @return ids An array of token IDs representing the replies.
     */
    function tokenReplies(uint256 tokenId) public view returns(uint256[] memory ids) {
        return tokenReplyIds[tokenId].values();
    }

    /**
     * @dev Internal function to set a token reply for a specific token ID.
     * @param id The token ID representing the reply.
     * @param tokenId The token ID to set the reply for.
     */
    function _setTokenReply(uint256 id, uint256 tokenId) internal {
        tokenReplyIds[tokenId].add(id);
    }

// Creator replies -----------------------------------------------------------
    mapping(address => EnumerableSet.UintSet) creatorReplies;

    /**
     * @dev Get the number of replies to a creator for an array of creator addresses.
     * @param toCreator An array of creator addresses.
     * @return count An array with the number of replies for each creator address.
     */
    function numberOfRepliesToCreatorBatch(address[] calldata toCreator) public view returns(uint256[] memory count) {
        uint256 len = toCreator.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; ++i) {
            count[i] = numberOfRepliesToCreator(toCreator[i]);
        }
    }

    /**
     * @dev Get the number of replies to a specific creator.
     * @param toCreator The address of the creator.
     * @return The number of replies to the creator.
     */
    function numberOfRepliesToCreator(address toCreator) public view returns(uint256) {
        return creatorReplies[toCreator].length();
    }

    /**
     * @dev Get an array of replies to a creator by their indices.
     * @param toCreator The address of the creator.
     * @param index An array of indices.
     * @return id An array of token IDs representing the replies.
     */
    function repliesToCreatorByIndexBatch(address toCreator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            id[i] = repliesToCreatorByIndex(toCreator, index[i]);
        }
    }

    /**
     * @dev Get a reply to a creator at a specific index.
     * @param toCreator The address of the creator.
     * @param index The index of the reply.
     * @return id The token ID representing the reply at the given index.
     */
    function repliesToCreatorByIndex(address toCreator, uint256 index) public view returns(uint256 id) {
        id = creatorReplies[toCreator].at(index);
    }

    /**
     * @dev Get an array of all token IDs representing the replies to a creator.
     * @param toCreator The address of the creator.
     * @return ids An array of token IDs representing the replies.
     */
    function repliesToCreator(address toCreator) public view returns(uint256[] memory ids) {
        return creatorReplies[toCreator].values();
    }

    /**
     * @dev Internal function to set a reply to a specific creator.
     * @param toCreator The address of the creator.
     * @param id The token ID representing the reply.
     */
    function _setCreatorReply(address toCreator, uint256 id) internal {
        creatorReplies[toCreator].add(id);
    }

// tag details -----------------------------------------------------------

    mapping(bytes32 => EnumerableMap.UintToUintMap) tagsDetails;

    /**
     * @dev Get the number of tokens with a specific tag for an array of tags.
     * @param tag An array of tags.
     * @return count An array with the number of tokens for each tag.
     */
    function numberOfTokensByTagBatch(bytes32[] calldata tag) public view returns(uint256[] memory count) {
        uint256 len = tag.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; ++i) {
            count[i] = numberOfTokensByTag(tag[i]);
        }
    }

    /**
     * @dev Get the number of tokens with a specific tag.
     * @param tag The tag to query.
     * @return The number of tokens with the given tag.
     */
    function numberOfTokensByTag(bytes32 tag) public view returns(uint256) {
        return tagsDetails[tag].length();
    }

    /**
     * @dev Get an array of tokens with a specific tag by their indices.
     * @param tag The tag to query.
     * @param index An array of indices.
     * @return id An array of token IDs with the specified tag.
     */
    function tokensOfTagByIndexBatch(bytes32 tag, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            id[i] = tokenOfTagByIndex(tag, index[i]);
        }
    }

    /**
     * @dev Get the token ID with a specific tag at a specific index.
     * @param tag The tag to query.
     * @param index The index of the token with the specified tag.
     * @return id The token ID with the specified tag at the given index.
     */
    function tokenOfTagByIndex(bytes32 tag, uint256 index) public view returns(uint256 id) {
        (id,) = tagsDetails[tag].at(index);
    }

    /**
     * @dev Get an array of all token IDs with a specific tag.
     * @param tag The tag to query.
     * @return ids An array of token IDs with the specified tag.
     */
    function tokensOfTag(bytes32 tag) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage tagIds = tagsDetails[tag];
        uint256 len = tagIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; ++i) {
            (ids[i],) = tagIds.at(i);
        }
    }

    /**
     * @dev Get the trace information for a token with a specific tag.
     * @param tag The tag to query.
     * @param id The ID of the token with the specified tag.
     * @return numberOfPreviousIds The number of tokens traced before this token.
     * @return numberOfNextIds The number of tokens traced after this token.
     * @return previousId The ID of the token traced before this token.
     * @return nextId The ID of the token traced after this token.
     */
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

    /**
     * @dev Internal function to set tag details for a token.
     * @param id The ID of the token to set the tag for.
     * @param tag The tag to set.
     */
    function _setTagDetails(uint256 id, bytes32 tag) private {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tag];
        if(!tagDetails.contains(id)){
            tagDetails.set(id, tagsDetails[tag].length());
        }
    }

    /**
     * @dev Internal function to register multiple tags for a token.
     * @param id The ID of the token to register tags for.
     * @param tags The array of tags to register.
     */
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
 