// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Katibeh1155.sol";
import "./utils/FeeManager.sol";
import "../utils/DataStorage.sol";
import "../utils/VerifySig.sol";
import "../utils/qHash.sol";

// data haye struct ro emit mikonim, payable address ha o share ha o exprire time ina ro store mikonim

// tooye faqat tokenId ro migiram o do ta array payment e dapp

// dapp data age por bood emitesh konim.

// do ta array ro ke male payable e dapp bood, ye array az struct mikonim.
contract Factory1155 is FeeManager, DataStorage {
    using qHash for bytes;
    using VerifySig for bytes;
    using Clones for address;
    using Strings for *;

    mapping(address => address) public _userCollection;
    mapping(uint256 => address) public _tokenCollection;

    Katibeh1155 public implementation = new Katibeh1155();


    event TokenData(uint256 indexed tokenId, bytes data);

    function fee(uint256 tokenId) public view returns(uint256) {
        uint256 supply = Katibeh1155(_tokenCollection[tokenId]).totalSupply(tokenId);
        return supply > 5 ? (supply - 5) * baseFee : 0;
    }

    function uri(uint256 tokenId) public view returns(string memory) {
        return Katibeh1155(_tokenCollection[tokenId]).uri(tokenId);
    }

    function getHash(Katibeh calldata katibeh) public pure returns(bytes32) {
        return keccak256(abi.encode(katibeh));
    }
    
    function collect1(
        uint256 tokenId,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data
    ) public {
        require(
            sig.verify(
                katibeh.creator,
                getHash(katibeh)
            ),
            "Katibeh721: Invalid signature"
        );
        require(
            tokenId == sig.q(),
            "Factory1155: wrong token id"
        );
        require(
            block.timestamp <= katibeh.expTime,
            "Factory1155: token sale time is expired"
        );
        require(
            block.timestamp >= katibeh.initTime,
            "Factory1155: token sale time has not started yet"
        );
        for(uint256 i; i < katibeh.toTokenId.length; i++) {
            require(
                Katibeh1155(_tokenCollection[katibeh.toTokenId[i]]).totalSupply(katibeh.toTokenId[i]) > 0,
                "Factory1155: to token id has not minted on current chain"
            );
        }
        address collectionAddr;
        Katibeh1155 k1155;

        if(_userCollection[katibeh.creator] == address(0)){
            collectionAddr = address(implementation).cloneDeterministic(
                bytes32(abi.encodePacked(katibeh.creator))
            );
            _userCollection[katibeh.creator] = collectionAddr;
            k1155 = Katibeh1155(collectionAddr);
            k1155.init(katibeh.creator, katibeh.creator.toHexString(), "Katibeh");
        } else {
            collectionAddr = _userCollection[katibeh.creator];
            k1155 = Katibeh1155(collectionAddr);
        }
            
        require(
            k1155.totalSupply(tokenId) == 0,
            "Factory1155: this collection has been already collected"
        );
        _tokenCollection[tokenId] = collectionAddr;
        k1155.mint(katibeh.creator, tokenId, 5, "");
        k1155.setURI(tokenId, katibeh.tokenURI);
        _setCollectData(tokenId, katibeh.toTokenId, katibeh.creator, katibeh.data, katibeh.mintTime, katibeh.initTime, katibeh.expTime);
    }

    function collect2(
        uint256 tokenId,
        bytes calldata dappData
    ) public payable {

        require(

        )

        uint256 _fee = fee(tokenId);
        require(
            msg.value >= _fee,
            "Factory1155: insufficient fee"
        );
            
        require(
            k1155.totalSupply(tokenId) == 0,
            "Factory1155: this collection has been already collected"
        );
        _payFees(katibeh.creator, _fee, katibeh.payableAddresses, katibeh.payableShares);

        if(msg.value > _fee) {
            payable(msg.sender).transfer(msg.value - _fee);
        }

        k1155.mint(msg.sender, tokenId, 1, "");
        if(katibeh.data.length != 0) {
            emit TokenData(tokenId, katibeh.data);
        }
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