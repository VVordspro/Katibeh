// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./utils/AllStorage.sol";
import "./utils/TraceStorage.sol";

interface IQVHash {
    function hash(
        DataStorage.Katibeh calldata katibeh,
        bytes calldata sig
    ) external view returns(uint256);
}

/**
 * @title Katibeh721
 * @dev A ERC721-compliant smart contract that represents Katibeh tokens.
 * 
 * @dev Katibeh721 is an extension of the ERC721 standard and implements the supportInterface of ERC721 and ERC721Enumerable.
 * 
 * @dev This contract includes features to store and manage token traces, creator tokens, creators, token replies, and tags.
 * 
 * @dev Users can mint freely their own collectibles here and burn if they want.
 * 
 * @dev Every collectible has a unique token ID and token URI.
 * 
 * @dev This is a free open-source project. DApp developers can customize their use cases and contribute to this contract as they desire.
 */
contract Katibeh721 is ERC721, ERC721Enumerable, ERC721Burnable, AllStorage, TraceStorage {
    using Strings for uint256;

    IQVHash public QVH;

    constructor(address qvhAddr) ERC721("Katibeh721", "KATIBEH") {
        QVH = IQVHash(qvhAddr);
    }

    /**
     * @dev Get the current timestamp.
     * @return Current timestamp as a uint256 value.
     */
    function timeStamp() public view returns(uint256) {
        return block.timestamp;
    }

    /**
     * @dev Compute and retrieve the hash of the provided Katibeh struct.
     * @param katibeh The input Katibeh struct whose hash will be calculated.
     * @return The keccak256 hash of the encoded Katibeh struct.
     */
    function getHash(DataStorage.Katibeh calldata katibeh) public view returns(bytes32) {
        require(
            block.timestamp >= katibeh.signTime - 1 hours &&
            block.timestamp < katibeh.signTime + 1 hours,
            "Katibeh721: more than 1 hours sign time difference."
        );
        return keccak256(abi.encode(katibeh));
    }

    /**
     * @dev Safely mint a new Katibeh ERC721 token and set its data.
     * 
     * @param katibeh The input Katibeh struct with token details.
     * @param sig The signature for the Katibeh token signed by the creator.
     * @param dappData Additional data related to the token.(optional parameter for dapps)
     * @return tokenId (tokenHash) The ID of the newly minted Katibeh token.
     * 
     * @dev The tokenID is computed using the keccak256 hash of the encoded Katibeh 
     *  struct and the signature provided by the creator.
     * 
     * @notice If the signature provided by the creator is invalid, the minting will fail.
     * 
     * @notice The keccak256 hash of the URI is registered, which means that other users are
     *  not allowed to use the same URI again.
     * 
     * @notice katibeh tokens are able to be collected multi-chain on ERC1155 collections.
     */
    function safeMint(
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata dappData
    ) public returns(uint256 tokenId) {
        tokenId = QVH.hash(katibeh, sig);
        tokenMintTime[tokenId] = block.timestamp;
        _safeMint(katibeh.creator, tokenId);
        _registerURI(katibeh.tokenURI, tokenId);
        _setMintData(tokenId, katibeh);
        _emitTags(tokenId, katibeh.tags);
        _setDappData(tokenId, dappData);
        _setSignature(tokenId, sig);
    }

    /**
     * @dev {safeMint}.
     * 
     * @dev This function stores all the data in networks that do not support the latest event protocol.
     */
    function safeMintAndSetTraceStorage( 
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata dappData
    ) public {
        uint256 tokenId = safeMint(katibeh, sig, dappData);

        _setTokenTraceable(tokenId);
        _setCreatorToken(katibeh.creator, tokenId);
        _addCreator(katibeh.creator);
        uint256 toIdLen = katibeh.toTokenHash.length;
        for (uint256 i; i < toIdLen; ++i){
            _setTokenReply(tokenId, katibeh.toTokenHash[i].tokenHash);
            _setCreatorReply(idToToken[katibeh.toTokenHash[i].tokenHash].creator, tokenId);
        }
        _registerTags(tokenId, katibeh.tags);
    }

    /**
     * @dev Internal function to handle the burning of a Katibeh token.
     *      It also clears the associated data.
     * @param tokenId The ID of the token to burn.
     */
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
        _burnData(tokenId);
    }

    /**
     * @dev Override for the ERC721 tokenURI function to get the URI of a given token.
     * @param tokenId The ID of the token.
     * @return The URI representing the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURI(tokenId);
    }


    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 firstTokenId, 
        uint256 batchSize
    )
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
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
 