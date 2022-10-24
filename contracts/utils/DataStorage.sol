// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DataStorage {
    mapping(uint256 => DS) idToDS;

    struct DS {
        string tokenURI;
        address creator;
        uint256 initTime;
        uint256 expTime;
    }

    function _setData(
        uint256 tokenId,
        string memory tokenURI,
        address creator,
        uint256 initTime,
        uint256 expTime
    ) internal {
        idToDS[tokenId] = DS(tokenURI, creator, initTime, expTime);
    }

    function getData(uint256 tokenId) public view returns(DS memory) {
        return idToDS[tokenId];
    }
}