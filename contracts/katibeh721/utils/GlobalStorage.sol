// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract GlobalStorage {
    
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;


// id details -----------------------------------------------------------

    EnumerableMap.UintToUintMap idDetails;

    function countAllIds() public view returns(uint256) {
        return idDetails.length();
    }

    function getAllIds() public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage allIds = idDetails;
        uint256 len = allIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = allIds.at(i);
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
        (idBefore,) = idDetails.at(numIdsBefore-1);
        (idAfter,) = idDetails.at(numIdsBefore+1);
    }

    function _setIdDetails(uint256 id) internal {
        idDetails.set(id, idDetails.length());
    }


// creator tokens -----------------------------------------------------------

    mapping(address => EnumerableMap.UintToUintMap) creatorTokens;

    function countAllIds(address creator) public view returns(uint256) {
        return creatorTokens[creator].length();
    }

    function getAllIds(address creator) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage creatorIds = creatorTokens[creator];
        uint256 len = creatorIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = creatorIds.at(i);
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
        (idBefore,) = creatorIds.at(numIdsBefore-1);
        (idAfter,) = creatorIds.at(numIdsBefore+1);
    }

    function _setCreatorToken(address creator, uint256 id) internal {
        creatorTokens[creator].set(id, creatorTokens[creator].length());
    }


// toToken details -----------------------------------------------------------

    mapping(uint256 => EnumerableSet.UintSet) tokenReplyIds;

    function countAllIds(uint256 toTokenId) public view returns(uint256) {
        return tokenReplyIds[toTokenId].length();
    }

    function getAllIds(uint256 toTokenId) public view returns(uint256[] memory ids) {
        return tokenReplyIds[toTokenId].values();
    }

    function _setTokenReply(uint256 id, uint256 toId) internal {
        tokenReplyIds[toId].add(id);
    }



// tag details -----------------------------------------------------------

    mapping(bytes32 => EnumerableMap.UintToUintMap) tagsDetails;

    function countAllIds(bytes32 tagHash) public view returns(uint256) {
        return tagsDetails[tagHash].length();
    }

    function getAllIds(bytes32 tagHash) public view returns(uint256[] memory ids) {
        EnumerableMap.UintToUintMap storage tagIds = tagsDetails[tagHash];
        uint256 len = tagIds.length();

        ids = new uint256[](len);

        for(uint256 i; i < len; i++) {
            (ids[i],) = tagIds.at(i);
        }
    }

    function getTagDetails(uint256 id, bytes32 tagHash) public view returns(
        uint256 numIdsBefore,
        uint256 numIdsAfter,
        uint256 idBefore,
        uint256 idAfter
    ) {
        EnumerableMap.UintToUintMap storage tagDetails = tagsDetails[tagHash];

        numIdsBefore = tagDetails.get(id);
        numIdsAfter = tagDetails.length() - numIdsBefore - 1;
        (idBefore,) = tagDetails.at(numIdsBefore-1);
        (idAfter,) = tagDetails.at(numIdsBefore+1);
    }

    function _setTagDetails(uint256 id, bytes32 tagHash) private {
        tagsDetails[tagHash].set(id, tagsDetails[tagHash].length());
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


// referrals --------------------------------------------------------------------



}