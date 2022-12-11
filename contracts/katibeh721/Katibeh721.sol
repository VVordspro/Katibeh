// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/qHash.sol";
import "../utils/VerifySig.sol";
import "../utils/DataStorage.sol";
import "./utils/GlobalStorage.sol";

contract Katibeh721 is ERC721, ERC721Enumerable, ERC721Burnable, DataStorage, GlobalStorage {
    using Strings for uint256;
    using qHash for string;
    using VerifySig for bytes;

    constructor() ERC721("Katibeh721", "KF") {}

    function getId(string calldata uri, uint256 mintTime) public pure returns(uint256 tokenId) {
        tokenId = uri.q(mintTime);
    }

    function mint(
        uint256 initTime,
        uint256 expTime,
        uint256 toTokenId,
        string calldata uri,
        string[] calldata tags,
        bytes calldata sig,
        bytes calldata data
    ) public {
        address creator = msg.sender;
        uint256 mintTime = block.timestamp;
        uint256 tokenId = getId(uri, mintTime);
        require(
            sig.verify(
                creator,
                toTokenId.toString(),
                initTime.toString(), 
                expTime.toString(),
                uri, 
                tags
            ),
            "Katibeh721: Invalid signature"
        );
        _safeMint(creator, tokenId);
        _registerURI(uri, tokenId);
        _setData(tokenId, toTokenId, uri, creator, mintTime, initTime, expTime, sig, data);
        _emitTags(tokenId, tags);
    }

    function safeMint(
        uint256 initTime,
        uint256 expTime,
        uint256 toTokenId,
        string calldata uri,
        string[] calldata tags,
        bytes calldata sig,
        bytes calldata data
    ) public {
        address creator = msg.sender;
        uint256 mintTime = block.timestamp;
        uint256 tokenId = getId(uri, mintTime);
        require(
            sig.verify(
                creator,
                toTokenId.toString(),
                initTime.toString(), 
                expTime.toString(),
                uri, 
                tags
            ),
            "Katibeh721: Invalid signature"
        );
        _safeMint(creator, tokenId);
        _registerURI(uri, tokenId);
        _setData(tokenId, toTokenId, uri, creator, mintTime, initTime, expTime, sig, data);
        _emitTags(tokenId, tags);

        _setIdDetails(tokenId);
        _setCreatorToken(creator, tokenId);
        _addCreator(creator);
        _registerTags(tokenId, tags);
        _setTokenReply(tokenId, toTokenId);
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
        _burnData(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        _requireMinted(tokenId);
        return _tokenURI(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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