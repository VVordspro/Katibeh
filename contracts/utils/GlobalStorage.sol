// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract GlobalStorage {
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;


// id details -----------------------------------------------------------

    EnumerableMap.UintToUintMap idDetails;

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


// tag details -----------------------------------------------------------

    mapping(bytes32 => EnumerableMap.UintToUintMap) tagsDetails;

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


// creator tokens -----------------------------------------------------------

    mapping(address => EnumerableSet.UintSet) creatorTokens;

    function getCreatorTokens(address creator) public view returns(uint256[] memory tokens) {
        EnumerableSet.UintSet storage tokensSet = creatorTokens[creator];
        uint256 len = tokensSet.length();

        tokens = new uint256[](len);

        for(uint256 i; i < len; i++) {
            tokens[i] = tokensSet.at(i);
        }
    }

    function _setCreatorToken(address creator, uint256 id) internal {
        creatorTokens[creator].add(id);
    }
}