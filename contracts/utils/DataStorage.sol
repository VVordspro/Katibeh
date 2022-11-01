// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DataStorage {

    mapping(string => uint256) URIsRegistered;

    mapping(uint256 => DS) idToDS;

    struct DS {
        string tokenURI;
        address creator;
        uint256 initTime;
        uint256 expTime;
    }

    function _registerURI(string calldata _uri, uint256 tokenId) internal {
        require(getUriId(_uri) == 0, "DataStorage: uri registered already");
        URIsRegistered[_uri] = tokenId;
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

    function getUriId(string calldata _uri) public view returns(uint256) {
        return URIsRegistered[_uri];
    }

    function getData(uint256 tokenId) public view returns(DS memory) {
        return idToDS[tokenId];
    }
}