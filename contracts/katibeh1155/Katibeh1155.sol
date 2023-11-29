// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./utils/Ownable.sol";

contract Katibeh1155 is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ERC1155URIStorage,
    Ownable,
    ERC2981
{
    constructor() ERC1155("") {
        Factory = msg.sender;
    }

    address immutable Factory;
    modifier onlyFactory() {
        require(
            msg.sender == Factory,
            "Katibeh1155: restricted access to the Factory"
        );
        _;
    }

    string public name;
    string public symbol;

    event TokenData(
        uint256 indexed id,
        address indexed addr,
        int8 indexed action,
        uint256 amount,
        bytes data
    );

    /**
     * @dev Initializes the contract with the given `owner_`, `name_`, and `symbol_` values.
     *     This function is marked as `public` and `initializer`.
     *
     * @param owner_ The address of the contract owner.
     * @param name_ The name of the contract.
     * @param symbol_ The symbol of the contract.
     */
    function init(
        address owner_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        name = name_;
        symbol = symbol_;
        __Ownable_init(owner_);
    }

    /**
     * @dev Returns the initial ID for the given `tokenId`.
     * 
     * @param tokenId The token ID for which to get the initial ID.
     * @return _tokenId The initial ID for the given `tokenId`.
     */
    function getInitialId(uint96 tokenId) public view returns (uint96 _tokenId) {
        _tokenId = tokenId;
        while (totalSupply(_tokenId) > 0) {
            _tokenId++;
        }
    }

    /**
     * @dev Mints tokens to the specified address.
     * 
     * @param addr The address to which the tokens will be minted.
     * @param id The ID of the token to be minted.
     * @param amount The amount of tokens to be minted.
     * @param data Additional data that can be attached to the minting operation.
     * @dev Only the factory contract can call this function.
     */
    function mint(
        address addr,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyFactory {
        _mint(addr, id, amount, data);
        if(data.length != 0){
            emit TokenData(id, addr, 1, amount, data);
        }
    }

    // /**
    //  * @dev Mints multiple tokens to the specified address in a batch.
    //  *
    //  * @param addr The address to which the tokens will be minted.
    //  * @param ids The array of token IDs to be minted.
    //  * @param amounts The array of amounts corresponding to each token ID to be minted.
    //  * @param data Additional data that can be attached to the minting operation.
    //  * @dev Only the factory contract can call this function.
    //  */
    // function mintBatch(
    //     address addr,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) public onlyFactory {
    //     _mintBatch(addr, ids, amounts, data);
    // }

    /**
     * @dev Sets the URI for a given token ID.
     * 
     * @param tokenId The ID of the token for which to set the URI.
     * @param tokenURI The URI to be set for the token.
     * @dev Only the factory contract can call this function.
     */
    function setURI(
        uint256 tokenId,
        string calldata tokenURI
    ) public onlyFactory {
        _setURI(tokenId, tokenURI);
    }

    /**
     * @dev Sets the royalty fee for a given token ID to be received by a specific address.
     * 
     * @param tokenId The ID of the token for which to set the royalty fee.
     * @param receiver The address that will receive the royalty fee.
     * @param feeNumerator The numerator of the royalty fee.
     * @dev Only the factory contract can call this function.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyFactory {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // The following functions are overrides required by Solidity.
    function uri(
        uint256 tokenId
    ) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return super.uri(tokenId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
