// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./utils/Ownable.sol";

contract Katibeh1155 is ERC1155, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage, Ownable {
    constructor() ERC1155("") {}

    address Factory;
    modifier onlyFactory() {
        require(msg.sender == Factory, "Katibeh1155: restricted access to the Factory");
        _;
    }

    string public name;
    string public symbol;

    function init(
        address owner_, 
        string memory name_, 
        string memory symbol_
    ) public onlyInitializing {
        name = name_;
        symbol = symbol_;
        Factory = msg.sender;
        __Ownable_init(owner_);
    }

    function mint(
        address addr,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyFactory {
        require(
            balanceOf(addr, id) == 0,
            "Mainnet Farsi: token collected already"
        );
        _mint(addr, id, amount, data);
    }

    function setURI(uint256 tokenId, string calldata tokenURI) public onlyFactory {
        _setURI(tokenId, tokenURI);
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