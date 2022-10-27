// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./utils/qHash.sol";
import "./utils/DataStorage.sol";

contract MumbaiFarsi is ERC1155, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage, DataStorage {
    using qHash for string;
    constructor() ERC1155("") {}

    function getId(
        string calldata tokenURI,
        address creator,
        uint256 expTime
    ) public pure returns(uint256 tokenId) {
        tokenId = tokenURI.q(creator, expTime);
    }

    function mint(
        string calldata tokenURI,
        uint256 expTime
    ) public {
        address creator = msg.sender;
        uint256 tokenId = getId(tokenURI, creator, expTime);

        _mint(creator, tokenId, 1, "");
        _setURI(tokenId, tokenURI);
        _setData(tokenId, tokenURI, creator, block.timestamp, expTime);
    }

    function name() public pure returns(string memory) {
        return "MumbaiFarsi";
    }

    function symbol() public pure returns(string memory) {
        return "MF";
    }
    
    // The following functions are overrides required by Solidity.
    function uri(uint256 tokenId) public view 
        override(ERC1155, ERC1155URIStorage)
        returns(string memory) 
    {
        return super.uri(tokenId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}