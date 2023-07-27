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
    mapping(address => uint256) public _collectorScore;

    Katibeh1155 public implementation = new Katibeh1155();
    IQHash public QH;

    event TokenData(uint256 indexed tokenId, bytes data);

    constructor(address qhAddr) {
        QH = IQHash(qhAddr);
        receiver1 = payable(msg.sender);
    }

    // function publicFee(uint256 tokenId) public view returns(uint256) {
    //     uint256 supply;
    //     if(_tokenCollection[tokenId] != address(0)){
    //         supply = Katibeh1155(_tokenCollection[tokenId]).totalSupply(tokenId);
    //     }
    //     return (supply + 1) * baseFee;
    // }

    // function privateFee(uint256 tokenId, Katibeh calldata katibeh) public view returns(uint256) {
    //     uint256 supply;
    //     if(_tokenCollection[tokenId] != address(0)){
    //         supply = Katibeh1155(_tokenCollection[tokenId]).totalSupply(tokenId);
    //     }
    //     return (supply + 1) * baseFee;
    // }

    function uri(uint256 tokenId) public view returns(string memory) {

        address addr = address(uint160(tokenId));
        if(_collectorScore[addr] != 0) {
            return 'data:application/json;base64,eyJuYW1lIjogIkthdGliZWgiLCJkZXNjcmlwdGlvbiI6ICJOb24tdHJhbnNmZXJhYmxlIiwiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTlRZM0lpQm9aV2xuYUhROUlqVTJOeUlnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4ZEdWNGRDQjRQU0kxTUNVaUlIazlJamN3SlNJZ2RHVjRkQzFoYm1Ob2IzSTlJbTFwWkdSc1pTSStTMkYwYVdKbGFEd3ZkR1Y0ZEQ0OEwzTjJaejQ9In0=';
        }

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

        address collector = msg.sender;

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
            address originAddr;
            if(isPublic(katibeh)) {
                require(
                    block.timestamp >= katibeh.signTime + 1 days,
                    "Factory1155: token sale time has not started yet"
                );
                _fee = publicFee(0);
            } else {

                _fee = privateFee(0, findPricing(katibeh));

                originAddr = katibeh.creator;
                require(
                    block.timestamp <= katibeh.expTime,
                    "Factory1155: token sale time is expired"
                );
                require(
                    block.timestamp >= katibeh.initTime,
                    "Factory1155: token sale time has not started yet"
                );
            }
            collectionAddr = predictCollectionAddr(originAddr, katibeh.tags[0]);
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
                _fee = publicFee(k1155.totalSupply(tokenId));
            } else {

                _fee = privateFee(k1155.totalSupply(tokenId), findPricing(katibeh));

                require(
                    block.timestamp <= katibeh.expTime,
                    "Factory1155: token sale time is expired"
                );
            }
        }

        require(
            msg.value >= _fee,
            "Factory1155: insufficient publicFee"
        );
        k1155.mint(collector, tokenId, 1, "");
        _collectorScore[collector] ++;
        emit TransferSingle(address(this), address(0), collector, uint256(uint160(collector)), 1);
        
        if(data.length != 0) {
            emit TokenData(tokenId, data);
        }

        if(msg.value > _fee) {
            payable(collector).transfer(msg.value - _fee);
        }
        _payFees(_fee, k1155.owner(), katibeh.owners, dapps);
    }

    function isPublic(Katibeh calldata katibeh) internal pure returns(bool) {
        return abi.encodePacked(katibeh.tags)[0] == 0x23;
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