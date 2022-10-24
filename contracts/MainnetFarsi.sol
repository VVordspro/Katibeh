// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./utils/qHash.sol";
import "./utils/DataStorage.sol";
import "./utils/FeeManager.sol";

contract MainnetFarsi is ERC1155, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage, DataStorage, FeeManager {
    using qHash for string;
    constructor() ERC1155("") {}

    function getId(
        string calldata tokenURI,
        address creator,
        uint256 expTime
    ) internal pure returns(uint256 tokenId) {
        tokenId = tokenURI.q(creator, expTime);
    }

    function fee(uint256 tokenId) public view returns(uint256) {
        return 10 ** 18 + (10 ** 18 * totalSupply(tokenId) * 25/1000);
    }

    function collect (
        uint256 tokenId,
        string calldata tokenURI,
        address creator,
        uint256 expTime,
        address[] calldata receivers, 
        uint16[] calldata fractions
    ) public payable{
        uint256 amount = 10 ** 18;
        address buyer = msg.sender;

        require(
            tokenId == getId(tokenURI, creator, expTime),
            "Mainnet Farsi: wrong token id"
        );

        require(
            msg.value >= fee(tokenId),
            "Mainnet Farsi: insufficient fee"
        );
        _payFees(creator, amount, receivers, fractions);

        if(totalSupply(tokenId) == 0){
            _mint(creator, tokenId, amount * 10, "");
            _setURI(tokenId, tokenURI);
            _setData(tokenId, tokenURI, creator, block.timestamp, expTime);
        }

        _mint(buyer, tokenId, amount, "");
    }

    function name() public pure returns(string memory) {
        return "MainnetFarsi";
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