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

// bad az taqirat check konam bebinam stack too deep mide ya na
// makhraje fraction haye hame array ha ro bardaram az majmoo e ona be dast biad
contract Katibeh721 is ERC721, ERC721Enumerable, ERC721Burnable, DataStorage, GlobalStorage {
    using Strings for uint256;
    using qHash for bytes;
    using VerifySig for bytes;

    constructor() ERC721("Katibeh721", "KF") {}

    function moment() public view returns(uint256) {
        return block.timestamp;
    }

    function getMessageHash(
        uint256[] calldata toTokenId,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime,
        string calldata uri,
        bytes32[] calldata tags,
        address[] calldata payableAddresses,
        uint16[] calldata payableShares
    ) public pure returns(bytes32) {
        require(
            payableAddresses.length == payableShares.length,
            "payable arrays must be the same lenght"
        );
        return VerifySig.getMessageHash(
            toTokenId,
            mintTime,
            initTime,
            expTime,
            uri,
            tags,
            payableAddresses,
            payableShares
        );
    }

    function getId(
        bytes calldata sig, 
        address creator
    ) public pure returns(uint256 tokenId) {
        tokenId = sig.q(creator);
    }

// ye voroodi be esme dapp data begiram
    function mint(Katibeh calldata katibeh) public returns(uint256 tokenId) {
        require(katibeh.mintTime < block.timestamp + 1 hours);
        
        tokenId = getId(katibeh.sig, katibeh.creator);
        require(
            katibeh.sig.verify(
                katibeh.creator,
                getMessageHash(
                    katibeh.toTokenId,
                    katibeh.mintTime,
                    katibeh.initTime,
                    katibeh.expTime,
                    katibeh.tokenURI,
                    katibeh.tags,
                    katibeh.payableAddresses,
                    katibeh.payableShares
                )
            ),
            "Katibeh721: Invalid signature"
        );
        _safeMint(katibeh.creator, tokenId);
        _registerURI(katibeh.tokenURI, tokenId);
        _setData(tokenId, katibeh);
        _emitTags(tokenId, katibeh.tags);
    }


    function globalMint(Katibeh calldata katibeh) public {
        uint256 tokenId = mint(katibeh);

        _setIdDetails(tokenId);
        _setCreatorToken(katibeh.creator, tokenId);
        _addCreator(katibeh.creator);
        uint256 toIdLen = katibeh.toTokenId.length;
        for (uint256 i; i < toIdLen; i++){
            _setTokenReply(tokenId, katibeh.toTokenId[i]);
            _setCreatorReply(idToToken[katibeh.toTokenId[i]].creator, tokenId);
        }
        _registerTags(tokenId, katibeh.tags);
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