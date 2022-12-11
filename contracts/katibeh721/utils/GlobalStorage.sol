// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract GlobalStorage {
    
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for *;


// id details -----------------------------------------------------------

    EnumerableMap.UintToUintMap idDetails;

    function countAllIds() public view returns(uint256) {
        return idDetails.length();
    }

    function idByIndex(uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = index.length;
        id = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            id[i] = idByIndex(index[i]);
        }
    }

    function idByIndex(uint256 index) public view returns(uint256 id) {
        (id,) = idDetails.at(index);
    }

    function getAllIds() public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage allIds = idDetails;
        uint256 len = allIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = allIds.at(i);
        }
    }

    function getIdDetails(uint256[] memory id) public view returns(
        uint256[] memory numIdsBefore,
        uint256[] memory numIdsAfter,
        uint256[] memory idBefore,
        uint256[] memory idAfter
    ) {
        uint256 len = id.length;
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
              = getIdDetails(id[i]);
        }

    }

    function getIdDetails(uint256 id) public view returns(
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

    function _setIdDetails(uint256 id) internal {
        idDetails.set(id, idDetails.length());
    }


// creator tokens -----------------------------------------------------------

    mapping(address => EnumerableMap.UintToUintMap) creatorTokens;

    function countAllIds(address[] calldata creator) public view returns(uint256[] memory count) {
        uint256 len = creator.length;
        count = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            count[i] = countAllIds(creator[i]);
        }
    }

    function countAllIds(address creator) public view returns(uint256) {
        return creatorTokens[creator].length();
    }

    function idByIndex(address[] calldata creator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = creator.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = idByIndex(creator[i], index[i]);
        }
    }

    function idByIndex(address creator, uint256 index) public view returns(uint256 id) {
        (id,) = creatorTokens[creator].at(index);
    }

    function getAllIds(address creator) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage creatorIds = creatorTokens[creator];
        uint256 len = creatorIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = creatorIds.at(i);
        }
    }

    function getIdDetails(address[] calldata creator, uint256[] calldata id) public view returns(
        uint256[] memory numIdsBefore,
        uint256[] memory numIdsAfter,
        uint256[] memory idBefore,
        uint256[] memory idAfter
    ) {
        uint256 len = creator.length;
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
              = getIdDetails(creator[i], id[i]);
        }
    }

    function getIdDetails(address creator, uint256 id) public view returns(
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

    function countAllCreators() public view returns(uint256) {
        return creators.length();
    }

    function creatorByIndex(uint256[] calldata index) public view returns(address[] memory creator) {
        uint256 len = index.length;
        creator = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            creator[i] = creatorByIndex(index[i]);
        }
    }

    function creatorByIndex(uint256 index) public view returns(address creator) {
        creator = creators.at(index);
    }

    function getAllCreators() public view returns(address[] memory c){
        return creators.values();
    }

    function _addCreator(address creator) internal {
        creators.add(creator);
    }

// Token replies -----------------------------------------------------------

    mapping(uint256 => EnumerableSet.UintSet) tokenReplyIds;

    function countAllReplies(uint256[] calldata toId) public view returns(uint256[] memory count) {
        uint256 len = toId.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = countAllReplies(toId[i]);
        }
    }

    function countAllReplies(uint256 toId) public view returns(uint256) {
        return tokenReplyIds[toId].length();
    }

    function replyByIndex(uint256[] calldata toId, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = toId.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = replyByIndex(toId[i], index[i]);
        }
    }

    function replyByIndex(uint256 toId, uint256 index) public view returns(uint256 id) {
        id = tokenReplyIds[toId].at(index);
    }

    function getAllReplies(uint256 toId) public view returns(uint256[] memory ids) {
        return tokenReplyIds[toId].values();
    }

    function _setTokenReply(uint256 id, uint256 toId) internal {
        tokenReplyIds[toId].add(id);
    }


// Creator replies -----------------------------------------------------------
    mapping(address => EnumerableSet.UintSet) creatorReplies;

    function countAllReplies(address[] calldata creator) public view returns(uint256[] memory count) {
        uint256 len = creator.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = countAllReplies(creator[i]);
        }
    }

    function countAllReplies(address creator) public view returns(uint256) {
        return creatorReplies[creator].length();
    }

    function replyByIndex(address[] calldata creator, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = creator.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = replyByIndex(creator[i], index[i]);
        }
    }

    function replyByIndex(address creator, uint256 index) public view returns(uint256 id) {
        id = creatorReplies[creator].at(index);
    }

    function getAllReplies(address creator) public view returns(uint256[] memory ids) {
        return creatorReplies[creator].values();
    }

    function _setCreatorReply(address creator, uint256 id) internal {
        creatorReplies[creator].add(id);
    }

// tag details -----------------------------------------------------------

    mapping(bytes32 => EnumerableMap.UintToUintMap) tagsDetails;

    function countAllIds(bytes32[] calldata tagHash) public view returns(uint256[] memory count) {
        uint256 len = tagHash.length;
        count = new uint256[](len);

        for(uint256 i = 0; i < len; i++) {
            count[i] = countAllIds(tagHash[i]);
        }
    }

    function countAllIds(bytes32 tagHash) public view returns(uint256) {
        return tagsDetails[tagHash].length();
    }

    function idByIndex(bytes32[] calldata tagHash, uint256[] calldata index) public view returns(uint256[] memory id) {
        uint256 len = tagHash.length;
        require(len == index.length, "input length difference");
        id = new uint256[](len);

        for (uint256 i; i < len; i++) {
            id[i] = idByIndex(tagHash[i], index[i]);
        }
    }

    function idByIndex(bytes32 tagHash, uint256 index) public view returns(uint256 id) {
        (id,) = tagsDetails[tagHash].at(index);
    }

    function getAllIds(bytes32 tagHash) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage tagIds = tagsDetails[tagHash];
        uint256 len = tagIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = tagIds.at(i);
        }
    }

    function getIdDetails(bytes32[] calldata tagHash, uint256[] calldata id) public view returns(
        uint256[] memory numIdsBefore,
        uint256[] memory numIdsAfter,
        uint256[] memory idBefore,
        uint256[] memory idAfter
    ) {
        uint256 len = tagHash.length;
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
              = getIdDetails(tagHash[i], id[i]);
        }
    }

    function getIdDetails(bytes32 tagHash, uint256 id) public view returns(
        uint256 numIdsBefore,
        uint256 numIdsAfter,
        uint256 idBefore,
        uint256 idAfter
    ) {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tagHash];

        numIdsBefore = tagDetails.get(id);
        numIdsAfter = tagDetails.length() - numIdsBefore - 1;
        if(numIdsBefore != 0) (idBefore,) = tagDetails.at(numIdsBefore-1);
        if(numIdsAfter != 0) (idAfter,) = tagDetails.at(numIdsBefore+1);
    }

    function _setTagDetails(uint256 id, bytes32 tagHash) private {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tagHash];
        if(!tagDetails.contains(id)){
            tagDetails.set(id, tagsDetails[tagHash].length());
        }
    }

    function _registerTag(uint256 id, string memory tag) private {
        _setTagDetails(id, keccak256(abi.encodePacked(tag)));
    }

    function _registerTags(uint256 id, string[] calldata tags) internal {
        require(tags.length == 3, "DataStorage: tags length must be 3");
        _registerTag(id, tags[0]);
        _registerTag(id, tags[1]);
        _registerTag(id, tags[2]);
        _registerTag(id, string.concat(tags[0], '/', tags[1]));
        _registerTag(id, string.concat(tags[1], '/', tags[2]));
        _registerTag(id, string.concat(tags[0], '/', tags[1], '/', tags[2]));
    }
}