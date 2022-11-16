// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./utils/qHash.sol";
import "./utils/DataStorage.sol";

contract Katibeh721 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, DataStorage {
    using qHash for string;

    constructor() ERC721("Katibeh721", "KF") {}

    function getId(
        string calldata _tokenURI,
        address creator,
        uint256 expTime
    ) public pure returns(uint256 tokenId) {
        tokenId = _tokenURI.q(creator, expTime);
    }

    function safeMint(
        string calldata _tokenURI,
        uint256 expTime,
        uint256 toTokenId,
        string[] calldata tags
    ) public {
        address creator = msg.sender;
        uint256 tokenId = getId(_tokenURI, creator, expTime);

        _safeMint(creator, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _registerURI(_tokenURI, tokenId);
        _setData(tokenId, _tokenURI, creator, toTokenId, block.timestamp, expTime);
        _emitTags(tokenId, tags);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}