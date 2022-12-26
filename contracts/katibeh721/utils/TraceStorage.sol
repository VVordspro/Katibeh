// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract TraceStorage {
    
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for *;


// id details -----------------------------------------------------------

    EnumerableMap.UintToUintMap idDetails;

    function totalSupplyTraceable() public view returns(uint256 count) {
        return idDetails.length();
    }

    function tokenByIndexTraceableBatch(uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            id[i] = tokenByIndexTraceable(index[i]);
        }
    }

    function tokenByIndexTraceable(uint256 index) public view returns(uint256 id) {
        (id,) = idDetails.at(index);
    }

    function traceTokenByTime(uint256 id) public view returns(
        uint256 numIdsBefore,
        uint256 numIdsAfter,
        uint256 idBefore,
        uint256 idAfter
    ) {
        numIdsBefore = idDetails.get(id);
        numIdsAfter = idDetails.length() - numIdsBefore - 1;
        if(numIdsBefore != 0) (idBefore,) = idDetails.at(numIdsBefore-1);
        if(numIdsAfter != 0) (idAfter,) = idDetails.at(numIdsBefore+1);
    }

    function _setTokenTraceable(uint256 id) internal {
        idDetails.set(id, idDetails.length());
    }


// creator tokens -----------------------------------------------------------

    mapping(address => EnumerableMap.UintToUintMap) creatorTokens;

    function totalSupplyOfCreatorBatch(address[] calldata creator) public view returns(uint256[] memory count) {
        uint256 len = creator.length;
        count = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            count[i] = totalSupplyOfCreator(creator[i]);
        }
    }

    function totalSupplyOfCreator(address creator) public view returns(uint256) {
        return creatorTokens[creator].length();
    }

    function tokenOfCreatorByIndexBatch(address[] calldata creator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = creator.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = tokenOfCreatorByIndex(creator[i], index[i]);
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
        uint256 numIdsBefore,
        uint256 numIdsAfter,
        uint256 idBefore,
        uint256 idAfter
    ) {
        EnumerableMap.UintToUintMap storage creatorIds = creatorTokens[creator];

        numIdsBefore = creatorIds.get(id);
        numIdsAfter = creatorIds.length() - numIdsBefore - 1;
        if(numIdsBefore != 0) (idBefore,) = creatorIds.at(numIdsBefore-1);
        if(numIdsAfter != 0) (idAfter,) = creatorIds.at(numIdsBefore+1);
    }

    function _setCreatorToken(address creator, uint256 id) internal {
        creatorTokens[creator].set(id, creatorTokens[creator].length());
    }


// creators ------------------------------------------------------------------

    EnumerableSet.AddressSet creators;

    function countCreators() public view returns(uint256) {
        return creators.length();
    }

    function creatorByIndexBatch(uint256[] calldata index) public view returns(address[] memory creator) {
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

    function countTokenRepliesBatch(uint256[] calldata tokenId) public view returns(uint256[] memory count) {
        uint256 len = tokenId.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = countTokenReplies(tokenId[i]);
        }
    }

    function countTokenReplies(uint256 tokenId) public view returns(uint256) {
        return tokenReplyIds[tokenId].length();
    }

    function tokenReplyByIndexBatch(uint256[] calldata tokenId, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = tokenId.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = tokenReplyByIndex(tokenId[i], index[i]);
        }
    }

    function tokenReplyByIndex(uint256 tokenId, uint256 index) public view returns(uint256 id) {
        id = tokenReplyIds[tokenId].at(index);
    }

    function tokenReplys(uint256 tokenId) public view returns(uint256[] memory ids) {
        return tokenReplyIds[tokenId].values();
    }

    function _setTokenReply(uint256 id, uint256 tokenId) internal {
        tokenReplyIds[tokenId].add(id);
    }


// Creator replies -----------------------------------------------------------
    mapping(address => EnumerableSet.UintSet) creatorReplies;

    function countCreatorReplies(address[] calldata toCreator) public view returns(uint256[] memory count) {
        uint256 len = toCreator.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = countCreatorReplies(toCreator[i]);
        }
    }

    function countCreatorReplies(address toCreator) public view returns(uint256) {
        return creatorReplies[toCreator].length();
    }

    function replyByIndex(address[] calldata toCreator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = toCreator.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = replyByIndex(toCreator[i], index[i]);
        }
    }

    function replyByIndex(address toCreator, uint256 index) public view returns(uint256 id) {
        id = creatorReplies[toCreator].at(index);
    }

    function getAllReplies(address toCreator) public view returns(uint256[] memory ids) {
        return creatorReplies[toCreator].values();
    }

    function _setCreatorReply(address toCreator, uint256 id) internal {
        creatorReplies[toCreator].add(id);
    }

// tag details -----------------------------------------------------------

    mapping(bytes32 => EnumerableMap.UintToUintMap) tagsDetails;

    function totalSupplyOfCreatorBatch(bytes32[] calldata tag) public view returns(uint256[] memory count) {
        uint256 len = tag.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = totalSupplyOfCreatorBatch(tag[i]);
        }
    }

    function totalSupplyOfCreatorBatch(bytes32 tag) public view returns(uint256) {
        return tagsDetails[tag].length();
    }

    function tokenByIndexTraceable(bytes32[] calldata tag, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = tag.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = tokenByIndexTraceable(tag[i], index[i]);
        }
    }

    function tokenByIndexTraceable(bytes32 tag, uint256 index) public view returns(uint256 id) {
        (id,) = tagsDetails[tag].at(index);
    }

    function getAllIds(bytes32 tag) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage tagIds = tagsDetails[tag];
        uint256 len = tagIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = tagIds.at(i);
        }
    }

    function traceTokenByIndex(bytes32[] calldata tag, uint256[] calldata id) public view returns(
        uint256[] memory numIdsBefore,
        uint256[] memory numIdsAfter,
        uint256[] memory idBefore,
        uint256[] memory idAfter
    ) {
        uint256 len = tag.length;
        require(len == id.length, "input length difference");

        numIdsBefore = new uint256[](len);
        numIdsAfter = new uint256[](len);
        idBefore = new uint256[](len);
        idAfter = new uint256[](len);


        for(uint256 i = 0; i < len; i++){
            (
                numIdsBefore[i],
                numIdsAfter[i],
                idBefore[i],
                idAfter[i]
            ) 
              = traceTokenByIndex(tag[i], id[i]);
        }
    }

    function traceTokenByIndex(bytes32 tag, uint256 id) public view returns(
        uint256 numIdsBefore,
        uint256 numIdsAfter,
        uint256 idBefore,
        uint256 idAfter
    ) {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tag];

        numIdsBefore = tagDetails.get(id);
        numIdsAfter = tagDetails.length() - numIdsBefore - 1;
        if(numIdsBefore != 0) (idBefore,) = tagDetails.at(numIdsBefore-1);
        if(numIdsAfter != 0) (idAfter,) = tagDetails.at(numIdsBefore+1);
    }

    function _setTagDetails(uint256 id, bytes32 tag) private {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tag];
        if(!tagDetails.contains(id)){
            tagDetails.set(id, tagsDetails[tag].length());
        }
    }

    function _registerTags(uint256 id, bytes32[] calldata tags) internal {
        require(tags.length == 3, "DataStorage: tags length must be 3");
        _setTagDetails(id, tags[0]);
        _setTagDetails(id, tags[1]);
        _setTagDetails(id, tags[2]);
        _setTagDetails(id, keccak256(abi.encodePacked(tags[0], tags[1])));
        _setTagDetails(id, keccak256(abi.encodePacked(tags[1], tags[2])));
        _setTagDetails(id, keccak256(abi.encodePacked(tags[0], tags[1], tags[2])));
    }
}