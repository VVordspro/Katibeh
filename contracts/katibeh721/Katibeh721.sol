// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/qHash.sol";
import "../utils/VerifySig.sol";
import "./utils/DataStorage.sol";
import "./utils/TraceStorage.sol";

contract Katibeh721 is ERC721, ERC721Enumerable, ERC721Burnable, DataStorage, TraceStorage {
    using Strings for uint256;
    using qHash for bytes;
    using VerifySig for bytes;

    constructor() ERC721("Katibeh721", "KATIBEH") {}

    function timeStamp() public view returns(uint256) {
        return block.timestamp;
    }

    function getHash(Katibeh calldata katibeh) public view returns(bytes32) {
        require(
            block.timestamp >= katibeh.signTime - 1 hours &&
            block.timestamp < katibeh.signTime + 1 hours,
            "Katibeh721: more than 1 hours sign time difference."
        );
        require(
            katibeh.signTime <= katibeh.initTime &&
            katibeh.initTime <= katibeh.expTime,
            "Katibeh721: sign time must be less than init time & init time must be less than expire time."
        );
        return keccak256(abi.encode(katibeh));
    }

    function safeMint(
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata dappData
    ) public returns(uint256 tokenId) {
        tokenId = sig.q();
        require(
            sig.verify(
                katibeh.creator,
                getHash(katibeh)
            ),
            "Katibeh721: Invalid signature"
        );
        tokenMintTime[tokenId] = block.timestamp;
        _safeMint(katibeh.creator, tokenId);
        _registerURI(katibeh.tokenURI, tokenId);
        _setMintData(tokenId, katibeh);
        _emitTags(tokenId, katibeh.tags);
        _setDappData(tokenId, dappData);
        _setSignature(tokenId, sig);
    }


    function safeMintAndSetTraceStorage( 
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata dappData
    ) public {
        uint256 tokenId = safeMint(katibeh, sig, dappData);

        _setTokenTraceable(tokenId);
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