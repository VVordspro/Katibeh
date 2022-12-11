// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Katibeh1155.sol";
import "./utils/FeeManager.sol";
import "../utils/DataStorage.sol";
import "../utils/VerifySig.sol";
import "../utils/qHash.sol";

contract Factory1155 is FeeManager, DataStorage {
    using qHash for string;
    using VerifySig for bytes;
    using Clones for address;
    using Strings for *;

    mapping(address => address) public _userCollection;
    mapping(uint256 => address) public _tokenCollection;

    Katibeh1155 public implementation = new Katibeh1155();


    function fee(uint256 tokenId) public view returns(uint256) {
        uint256 supply = Katibeh1155(_tokenCollection[tokenId]).totalSupply(tokenId);
        return supply > 5 ? supply * 10 ** 18 - 5 : 0;
    }

    function uri(uint256 tokenId) public view returns(string memory) {
        return Katibeh1155(_tokenCollection[tokenId]).uri(tokenId);
    }

    function getId(string calldata _tokenURI, uint256 mintTime) public pure returns(uint256 tokenId) {
        tokenId = _tokenURI.q(mintTime);
    }

    function collect(
        uint256 tokenId,
        uint256 toTokenId,
        string calldata tokenURI,
        address creator,
        uint256 mintTime,
        uint256 initTime,
        uint256 expTime,
        string[] calldata tags,
        bytes calldata sig,
        address[] calldata receivers, 
        uint16[] calldata fractions
    ) public payable {
        require(
            sig.verify(
                creator,
                toTokenId.toString(),
                initTime.toString(), 
                expTime.toString(),
                tokenURI, 
                tags
            ),
            "Katibeh721: Invalid signature"
        );
        require(
            tokenId == getId(tokenURI, mintTime),
            "Factory1155: wrong token id"
        );
        require(
            block.timestamp <= expTime,
            "Factory1155: token sale time is expired"
        );
        require(
            block.timestamp >= initTime,
            "Factory1155: token sale time has not started yet"
        );
        require(
            block.timestamp >= initTime,
            "Factory1155: token sale time has not started yet"
        );
        require(
            Katibeh1155(_tokenCollection[toTokenId]).totalSupply(toTokenId) > 0,
            "Factory1155: to token id has not minted on current chain"
        );

        address collectionAddr;
        uint256 _fee;
        Katibeh1155 k1155;

        if(_userCollection[creator] == address(0)){
            collectionAddr = address(implementation).cloneDeterministic(
                bytes32(abi.encodePacked(creator))
            );
            _userCollection[creator] = collectionAddr;
            k1155 = Katibeh1155(collectionAddr);
            k1155.init(creator, creator.toHexString(), "Katibeh");
        } else {
            collectionAddr = _userCollection[creator];
            k1155 = Katibeh1155(collectionAddr);
        }
            
        if(k1155.totalSupply(tokenId) == 0) {
            _tokenCollection[tokenId] = collectionAddr;
            k1155.mint(creator, tokenId, 5, "");
            k1155.setURI(tokenId, tokenURI);
            _emitData(tokenId, toTokenId, creator, mintTime, initTime, expTime);
        } else {
            _fee = fee(tokenId);
            require(
                msg.value >= _fee,
                "Factory1155: insufficient fee"
            );
            _payFees(creator, _fee, receivers, fractions);
        }

        if(msg.value > _fee) {
            payable(msg.sender).transfer(msg.value - _fee);
        }

        k1155.mint(msg.sender, tokenId, 1, "");
    }

    function predictCollectionAddr(
        address creatorAddr
    ) public view returns(address) {
        return address(implementation).predictDeterministicAddress(
            bytes32(abi.encodePacked(creatorAddr)), 
            address(this)
        );
    }
}