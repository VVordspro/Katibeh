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
        uint256 tokenId
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

    constructor(ISplitter _split, address qhAddr) 
        FeeManager(_split) 
    {
        QH = IQHash(qhAddr);
        receiver1 = payable(msg.sender);
    }
    
    function fee(
        uint256 tokenId, 
        Katibeh calldata katibeh
    ) public view returns(uint256 _fee) {
        (_fee,) = feeAndSupply(tokenId, katibeh);
    }
    
    function feeAndSupply(
        uint256 tokenId, 
        Katibeh calldata katibeh
    ) public view returns(
        uint256 _fee, 
        uint256 supply
    ) {
        address collAddr = _tokenCollection[tokenId];
        Katibeh1155 k1155;
        if(collAddr != address(0)){
            k1155 = Katibeh1155(collAddr);
            supply = k1155.totalSupply(tokenId);
        }
        if(isPublic(katibeh.tags)) {
            _fee = publicFee(supply);
        } else {
            _fee = privateFee(supply, findPricing(katibeh));
        }
    }

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
        ISplitter.Share[] calldata dapps
    ) public payable {
        collectTo(msg.sender, tokenId, katibeh, sig, data, dapps);
    }

    function collectTo(
        address collector,
        uint256 tokenId,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
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
            uint96 royalty;
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
            if(isPublic(katibeh.tags)) {
                require(
                    block.timestamp >= katibeh.signTime + 1 days,
                    "Factory1155: token sale time has not started yet"
                );
                _fee = publicFee(0);
            } else {

                Pricing memory pricing = findPricing(katibeh);

                _fee = privateFee(0, pricing);

                originAddr = katibeh.creator;
                require(
                    block.timestamp <= pricing.expTime,
                    "Factory1155: token sale time is expired"
                );
                require(
                    block.timestamp >= katibeh.initTime,
                    "Factory1155: token sale time has not started yet"
                );
                royalty = pricing.royalty;
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
            if(royalty > 0) {
                address royaltyReceiver;
                if(katibeh.owners.length == 0){
                    royaltyReceiver = katibeh.creator;
                } else {
                    royaltyReceiver = split.getPredictedSplitAddress(katibeh.owners);
                }
                k1155.setTokenRoyalty(tokenId, royaltyReceiver, royalty);
            }

        } else {
            // collect
            k1155 = Katibeh1155(collectionAddr);

            if(isPublic(katibeh.tags)){
                _fee = publicFee(k1155.totalSupply(tokenId));
            } else {
                Pricing memory pricing = findPricing(katibeh);
                _fee = privateFee(k1155.totalSupply(tokenId), pricing);

                require(
                    block.timestamp <= pricing.expTime,
                    "Factory1155: token sale time is expired"
                );
            }
        }

        require(
            msg.value >= _fee,
            "Factory1155: insufficient Fee"
        );
        k1155.mint(collector, tokenId, 1, "");
        _collectorScore[collector] ++;
        emit TransferSingle(address(this), address(0), collector, uint256(uint160(collector)), 1);
        
        if(data.length != 0) {
            emit TokenData(tokenId, data);
        }

        if(msg.value > _fee) {
            payable(msg.sender).transfer(msg.value - _fee);
        }
        _payFees(_fee, _getPayableOwner(katibeh.owners, katibeh.creator), dapps);
    }

    function isPublic(bytes32[] calldata tags) internal pure returns(bool) {
        return tags[0][0] == 0x23;
    }

    function predictCollectionAddr(
        address creatorAddr,
        bytes32 tag0
    ) internal view returns(address) {
        return address(implementation).predictDeterministicAddress(
            bytes32(abi.encodePacked(creatorAddr, tag0)), 
            address(this)
        );
    }

    function predictCollAddr(
        address creatorAddr,
        string memory tag0
    ) external view returns(address) {
        return address(implementation).predictDeterministicAddress(
            bytes32(abi.encodePacked(creatorAddr, bytes32(abi.encode(tag0)))), 
            address(this)
        );
    }

    function firstPublicCollect(
        address collector,
        uint256 tokenId,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        _checkFirstCollect(tokenId, katibeh, sig);
        _checkToTokenId(katibeh.toTokenId);
        uint256 _fee = _checkPublicCollect(katibeh, 0);
        Katibeh1155 k1155 = Katibeh1155(_getCreateCollectionAddr(address(0), katibeh));
        address royaltyReceiver = _getPayableOwner(katibeh.owners, katibeh.creator);
        _setTokenData(tokenId, 0, k1155, royaltyReceiver, katibeh);
        _collect(k1155, collector, tokenId);
        _payFees(_fee, royaltyReceiver, dapps);
        _emitData(data, tokenId);
    }

    function firstPrivateCollect(
        address collector,
        uint256 tokenId,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        _checkFirstCollect(tokenId, katibeh, sig);
        _checkToTokenId(katibeh.toTokenId);
        (uint256 _fee, uint96 royalty) = _checkPrivateCollect(katibeh, 0, tokenId);
        Katibeh1155 k1155 = Katibeh1155(_getCreateCollectionAddr(katibeh.creator, katibeh));
        address royaltyReceiver = _getPayableOwner(katibeh.owners, katibeh.creator);
        _setTokenData(tokenId, royalty, k1155, royaltyReceiver, katibeh);
        _collect(k1155, collector, tokenId);
        _payFees(_fee, royaltyReceiver, dapps);
        _emitData(data, tokenId);
    }

    function publicCollect(
        address collector,
        uint256 tokenId,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        Katibeh1155 k1155 = Katibeh1155(_tokenCollection[tokenId]);
        uint256 _fee = publicFee(k1155.totalSupply(tokenId));
        _collect(k1155, collector, tokenId);
        (address royaltyReceiver,) = k1155.royaltyInfo(tokenId, 0);
        _payFees(_fee, royaltyReceiver, dapps);
        _emitData(data, tokenId);
    }

    function privateCollect(
        address collector,
        uint256 tokenId,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        Katibeh1155 k1155 = Katibeh1155(_tokenCollection[tokenId]);
        uint256 _fee = privateFee(k1155.totalSupply(tokenId), tokenPricing[tokenId]);
        _collect(k1155, collector, tokenId);
        (address royaltyReceiver,) = k1155.royaltyInfo(tokenId, 0);
        _payFees(_fee, royaltyReceiver, dapps);
        _emitData(data, tokenId);
    }

    function _checkFirstCollect(uint256 tokenId, Katibeh calldata katibeh, bytes calldata sig) internal view {
        require(_tokenCollection[tokenId] == address(0), "Factory1155: This is not the first collect");
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
    }

    function _checkToTokenId(uint256[] calldata toTokenId) internal view {
            uint256 len = toTokenId.length;
            for(uint256 i; i < len; ++i) {
                address colAddr = _tokenCollection[toTokenId[i]];
                require(
                    colAddr != address(0) &&
                    Katibeh1155(colAddr).totalSupply(toTokenId[i]) > 0,
                    "Factory1155: to token id has not minted on current chain"
                );
            }
    }

    function _checkPublicCollect(Katibeh calldata katibeh, uint256 supply) internal view returns(uint256 _fee) {
        require(isPublic(katibeh.tags), "Factory1155: Only public collect allowed.");
        require(
            block.timestamp >= katibeh.signTime + 1 days,
            "Factory1155: token sale time has not started yet"
        );
        _fee = publicFee(supply);
    }

    function _checkPrivateCollect(Katibeh calldata katibeh, uint256 supply, uint256 tokenId) internal returns(
        uint256 _fee, 
        uint96 royalty
    ) {
        require(!isPublic(katibeh.tags), "Factory1155: Only private collect allowed.");

        Pricing memory pricing = findPricing(katibeh);

        _fee = privateFee(supply, pricing);

        require(
            block.timestamp <= pricing.expTime,
            "Factory1155: token sale time is expired"
        );
        require(
            block.timestamp >= katibeh.initTime,
            "Factory1155: token sale time has not started yet"
        );
        royalty = pricing.royalty;
        _setPricing(tokenId, pricing);
    }

    function _getCreateCollectionAddr(
        address originAddr, 
        Katibeh calldata katibeh
    ) internal returns(address collectionAddr) {
        Katibeh1155 k1155;
        collectionAddr = predictCollectionAddr(originAddr, katibeh.tags[0]);            k1155 = Katibeh1155(collectionAddr);
        if(collectionAddr.code.length == 0){
            address(implementation).cloneDeterministic(
                bytes32(abi.encodePacked(katibeh.creator, katibeh.tags[0]))
            );
            k1155.init(katibeh.creator, string(abi.encode(katibeh.tags[0])), "Katibeh");
        }
    }

    function _setTokenData(
        uint256 tokenId, 
        uint96 royalty,
        Katibeh1155 k1155,
        address royaltyReceiver,
        Katibeh calldata katibeh
    ) internal {
        _tokenCollection[tokenId] = address(k1155);
        k1155.setURI(tokenId, katibeh.tokenURI);
        _setCollectData(tokenId, katibeh);
        k1155.setTokenRoyalty(tokenId, royaltyReceiver, royalty);
    }

    function _collect(Katibeh1155 k1155, address collector, uint256 tokenId) internal {
        k1155.mint(collector, tokenId, 1, "");
        _collectorScore[collector] ++;
        emit TransferSingle(address(this), address(0), collector, uint256(uint160(collector)), 1);
    }

    function _emitData(bytes calldata data, uint256 tokenId) internal {
        if(data.length != 0) {
            emit TokenData(tokenId, data);
        }
    }

    function _getPayableOwner(ISplitter.Share[] memory owners, address creator) internal returns(address) {
        uint256 len = owners.length;
        if(len == 0) {
            return creator; // return the creator if there are no owners
        } else if(len == 1) {
            return owners[0].recipient;
        } else {
            return address(split.createSplit(owners)); // return the splitter for specified owners.
        }
    }

    function _setPricing(uint256 tokenId, Pricing memory pricing) internal {
        Pricing storage p = tokenPricing[tokenId];
        p.A = pricing.A;
        p.B = pricing.B;
        p.C = pricing.C;
        p.D = pricing.D;
        p.totalSupply = pricing.totalSupply;
        p.expTime = pricing.expTime;
        p.discount = pricing.discount;
    }
} 