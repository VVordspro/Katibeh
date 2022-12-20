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

    function moment() public view returns(uint256) {
        return block.timestamp;
    }

    function getMessageHash(
        uint256 toTokenId,
        uint256 initTime,
        uint256 expTime,
        string calldata uri,
        string[] calldata tags
    ) public pure returns(bytes32) {
        return VerifySig.getMessageHash(
            toTokenId,
            initTime,
            expTime,
            uri,
            tags
        );
    }

    function getId(
        string calldata uri, 
        address creator,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime
    ) public pure returns(uint256 tokenId) {
        tokenId = uri.q(creator, mintTime, initTime, expTime);
    }


    //ye doone function public e get message hash bezaram dapp ono bar midare sign mikone
    // verify ro ham sade konam text haye bi fayde ro pak konam

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
        uint256 tokenId = getId(uri, creator, mintTime, initTime, expTime);
        require(
            sig.verify(
                creator,
                getMessageHash(
                    toTokenId,
                    initTime,
                    expTime,
                    uri,
                    tags
                )
            ),
            "Katibeh721: Invalid signature"
        );
        _safeMint(creator, tokenId);
        _registerURI(uri, tokenId);
        _setData(tokenId, toTokenId, uri, creator, mintTime, initTime, expTime, sig, data);
        _emitTags(tokenId, tags);
    }

    function globalMint(
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
        uint256 tokenId = getId(uri, creator, mintTime, initTime, expTime);
        require(
            sig.verify(
                creator,
                getMessageHash(
                    toTokenId,
                    initTime,
                    expTime,
                    uri,
                    tags
                )
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
        if(toTokenId != 0){
            _setTokenReply(tokenId, toTokenId);
            _setCreatorReply(idToDS[toTokenId].creator, tokenId);
        }
        _registerTags(tokenId, tags);
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
        require(
            from == address(0) || to == address(0),
            "tokens cannot be transfered on testnet"
        );
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