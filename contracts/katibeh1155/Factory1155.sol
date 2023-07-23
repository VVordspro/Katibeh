// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Katibeh1155.sol";
import "./utils/FeeManager.sol";
import "../QHash/utils/VerifySig.sol";


interface IQHash {
      function checkHash(
        bytes calldata sig,
        uint256 hash
    ) external pure returns(bool);
}

contract Factory1155 is FeeManager {
    using VerifySig for bytes;
    using Clones for address;
    using Strings for *;

    mapping(uint256 => address) public _tokenCollection;

    Katibeh1155 public implementation = new Katibeh1155();
    IQHash public QH;

    event TokenData(uint256 indexed tokenId, bytes data);

    constructor(address qhAddr) {
        QH = IQHash(qhAddr);
    }

    function fee(uint256 tokenId) public view returns(uint256) {
        uint256 supply;
        if(_tokenCollection[tokenId] != address(0)){
            supply = Katibeh1155(_tokenCollection[tokenId]).totalSupply(tokenId);
        }
        return supply > 5 ? (supply - 5) * baseFee : 0;
    }

    function uri(uint256 tokenId) public view returns(string memory) {
        return Katibeh1155(_tokenCollection[tokenId]).uri(tokenId);
    }

    function getHash(Katibeh calldata katibeh) internal pure returns(bytes32) {
        return keccak256(abi.encode(katibeh));
    }

    function collect(
        uint256 tokenId,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        Payee[] calldata dapps
    ) public payable {
        address collectionAddr = _tokenCollection[tokenId];
        Katibeh1155 k1155;
        uint256 _fee;

        if(collectionAddr == address(0)) {
            // first collect
            require(
                sig.verify(
                    katibeh.creator,
                    getHash(katibeh)
                ),
                "Factory1155: Invalid signature"
            );
            require(
                QH.checkHash(sig, tokenId),
                "Factory1155: wrong token id"
            );
            uint256 len = katibeh.toTokenId.length;
            for(uint256 i; i < len; ++i) {
                address colAddr = _tokenCollection[katibeh.toTokenId[i]];
                require(
                    colAddr != address(0) &&
                    Katibeh1155(colAddr).totalSupply(katibeh.toTokenId[i]) > 0,
                    "Factory1155: to token id has not minted on current chain"
                );
            }
            address creatorAddr;
            if(isPublic(katibeh)) {
                _fee = fee(tokenId);
            } else {

                // get fee should be handled

                creatorAddr = katibeh.creator;
                require(
                    block.timestamp <= katibeh.expTime,
                    "Factory1155: token sale time is expired"
                );
                require(
                    block.timestamp >= katibeh.initTime,
                    "Factory1155: token sale time has not started yet"
                );
            }
            collectionAddr = predictCollectionAddr(creatorAddr, katibeh.tags[0]);
            k1155 = Katibeh1155(collectionAddr);

            if(collectionAddr.code.length == 0){
                address(implementation).cloneDeterministic(
                    bytes32(abi.encodePacked(katibeh.creator, katibeh.tags[0]))
                );
                k1155.init(katibeh.creator, string(abi.encode(katibeh.tags[0])), "Katibeh");
            }
            _tokenCollection[tokenId] = collectionAddr;
            k1155.setURI(tokenId, katibeh.tokenURI);
            _setCollectData(tokenId, katibeh);

        } else {
            // collect
            k1155 = Katibeh1155(collectionAddr);


            if(isPublic(katibeh)){
            _fee = fee(tokenId);
            } else {

                // get fee should be handled

                require(
                    block.timestamp <= katibeh.expTime,
                    "Factory1155: token sale time is expired"
                );
            }

        }

        require(
            msg.value >= _fee,
            "Factory1155: insufficient fee"
        );
        if(msg.value > _fee) {
            payable(msg.sender).transfer(msg.value - _fee);
        }
        k1155.mint(msg.sender, tokenId, 1, "");
        if(data.length != 0) {
            emit TokenData(tokenId, data);
        }
        _payFees(_fee, k1155.owner(), katibeh.owners, dapps);
    }

    function isPublic(Katibeh calldata katibeh) internal pure returns(bool) {
        return abi.encodePacked(katibeh.tags)[0] == 0x40;
    }

    function predictCollectionAddr(
        address creatorAddr,
        bytes32 tag0
    ) public view returns(address) {
        return address(implementation).predictDeterministicAddress(
            bytes32(abi.encodePacked(creatorAddr, tag0)), 
            address(this)
        );
    }
} 