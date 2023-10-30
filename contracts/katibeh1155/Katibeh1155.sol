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
    constructor() ERC1155("") {}

    address Factory;
    modifier onlyFactory() {
        require(
            msg.sender == Factory,
            "Katibeh1155: restricted access to the Factory"
        );
        _;
    }

    string public name;
    string public symbol;

    function init(
        address owner_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        name = name_;
        symbol = symbol_;
        Factory = msg.sender;
        __Ownable_init(owner_);
    }

    function getInitialId(uint96 tokenId) public view returns(uint96 _tokenId) {
        _tokenId = tokenId;
        while(totalSupply(_tokenId) > 0) {
            _tokenId ++;
        }
    }

    function mint(
        address addr,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyFactory {
        _mint(addr, id, amount, data);
    }

    function setURI(
        uint256 tokenId,
        string calldata tokenURI
    ) public onlyFactory {
        _setURI(tokenId, tokenURI);
    }

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
