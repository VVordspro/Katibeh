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
        uint256 tokenHash
    ) external pure returns(bool);
}

contract Factory1155 is FeeManager {
    using VerifySig for bytes;
    using Clones for address;
    using Strings for *;

    struct Collection{
        address addr;
        uint96 tokenId;
    }
    mapping(uint256 => Collection) public _tokenCollection;
    mapping(address => uint256) public _collectorScore;
    mapping(address => mapping(uint96 => uint256)) initialSupply;
    mapping(address => mapping(uint96 => ISplitter.Share[])) tokenOwners;

    Katibeh1155 immutable public implementation;
    IQHash public QH;
    uint96 public startTime;

    event TokenData(uint256 indexed tokenHash, bytes data);

    constructor(ISplitter _split, address qhAddr, uint96 _startTime) 
        FeeManager(_split) 
    {
        implementation = new Katibeh1155();
        QH = IQHash(qhAddr);
        receiver1 = payable(msg.sender);
        startTime = _startTime;
    }
    
    // function fee(
    //     uint256 tokenHash, 
    //     uint256 amount,
    //     Katibeh calldata katibeh
    // ) public view returns(uint256 _fee) {
    //     (_fee,) = feeAndSupply(tokenHash, amount, katibeh);
    // }

    function _getInitialTokenId(uint96 signTime, Katibeh1155 k1155) internal view returns(uint96 tokenId) {
        return k1155.getInitialId(signTime - startTime);
    }
    
    // function feeAndSupply(
    //     uint256 tokenHash, 
    //     uint256 amount,
    //     Katibeh calldata katibeh
    // ) public view returns(
    //     uint256 _fee, 
    //     uint256 supply
    // ) {
    //     address collAddr = _tokenCollection[tokenHash].addr;
    //     Katibeh1155 k1155;
    //     if(collAddr != address(0)){
    //         k1155 = Katibeh1155(collAddr);
    //         supply = k1155.totalSupply(tokenHash);
    //     }
    //     if(isPublic(katibeh.tags[0])) {
    //         _fee = publicFee(supply);
    //     } else {
    //         _fee = privateFee(supply, amount, findPricing(katibeh));
    //     }
    // }

    function uri(uint256 tokenHash) public view returns(string memory) {

        address addr = address(uint160(tokenHash));
        if(_collectorScore[addr] != 0) {
            return 'data:application/json;base64,eyJuYW1lIjogIkthdGliZWgiLCJkZXNjcmlwdGlvbiI6ICJOb24tdHJhbnNmZXJhYmxlIiwiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTlRZM0lpQm9aV2xuYUhROUlqVTJOeUlnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4ZEdWNGRDQjRQU0kxTUNVaUlIazlJamN3SlNJZ2RHVjRkQzFoYm1Ob2IzSTlJbTFwWkdSc1pTSStTMkYwYVdKbGFEd3ZkR1Y0ZEQ0OEwzTjJaejQ9In0=';
        }
        Collection memory coll = _tokenCollection[tokenHash];
        return Katibeh1155(coll.addr).uri(coll.tokenId);
    }

    function getHash(Katibeh calldata katibeh) internal pure returns(bytes32) {
        return keccak256(abi.encode(katibeh));
    }

    // function collect(
    //     uint256 tokenHash,
    //     uint256 amount,
    //     Katibeh calldata katibeh,
    //     bytes calldata sig,
    //     bytes calldata data,
    //     ISplitter.Share[] calldata dapps
    // ) public payable {
    //     collectTo(msg.sender, tokenHash, amount, katibeh, sig, data, dapps);
    // }

    // function collectTo(
    //     address collector,
    //     uint256 tokenHash,
    //     uint256 amount,
    //     Katibeh calldata katibeh,
    //     bytes calldata sig,
    //     bytes calldata data,
    //     ISplitter.Share[] calldata dapps
    // ) public payable {
    //     Collection memory coll = _tokenCollection[tokenHash];
    //     Katibeh1155 k1155;
    //     uint256 _fee;

    //     if(coll.addr == address(0)) {
    //         // first collect
    //         require(
    //             sig.verify(
    //                 katibeh.creator,
    //                 getHash(katibeh)
    //             ),
    //             "Factory1155: Invalid signature"
    //         );
    //         require(
    //             QH.checkHash(sig, tokenHash),
    //             "Factory1155: wrong token id"
    //         );
    //         uint96 royalty;
    //         uint256 len = katibeh.toTokenHash.length;
    //         for(uint256 i; i < len; ++i) {
    //             address colAddr = _tokenCollection[katibeh.toTokenHash[i]].addr;
    //             require(
    //                 colAddr != address(0) &&
    //                 Katibeh1155(colAddr).totalSupply(katibeh.toTokenHash[i]) > 0,
    //                 "Factory1155: to token id has not minted on current chain"
    //             );
    //         }
    //         address originAddr;
    //         if(isPublic(katibeh.tags[0])) {
    //             require(
    //                 block.timestamp >= katibeh.signTime + 1 days,
    //                 "Factory1155: token sale time has not started yet"
    //             );
    //             _fee = publicFee(0);
    //         } else {

    //             Pricing memory pricing = findPricing(katibeh);

    //             _fee = privateFee(0, amount, pricing);

    //             originAddr = katibeh.creator;
    //             require(
    //                 block.timestamp <= pricing.expTime,
    //                 "Factory1155: token sale time is expired"
    //             );
    //             require(
    //                 block.timestamp >= katibeh.initTime,
    //                 "Factory1155: token sale time has not started yet"
    //             );
    //             royalty = pricing.royalty;
    //         }
    //         coll.addr = predictCollectionAddr(originAddr, katibeh.tags[0]);
    //         k1155 = Katibeh1155(coll.addr);

    //         if(coll.addr.code.length == 0){
    //             address(implementation).cloneDeterministic(
    //                 bytes32(abi.encodePacked(katibeh.creator, katibeh.tags[0]))
    //             );
    //             k1155.init(katibeh.creator, string(abi.encode(katibeh.tags[0])), "Katibeh");
    //         }
    //         coll.tokenId = _getInitialTokenId(katibeh.signTime, k1155);
    //         _tokenCollection[tokenHash] = coll;

    //         k1155.setURI(coll.tokenId, katibeh.tokenURI);
    //         _firstEmits(tokenHash, katibeh);
    //         if(royalty > 0) {
    //             address royaltyReceiver;
    //             if(katibeh.owners.length == 0){
    //                 royaltyReceiver = katibeh.creator;
    //             } else {
    //                 royaltyReceiver = split.getPredictedSplitAddress(katibeh.owners);
    //             }
    //             k1155.setTokenRoyalty(coll.tokenId, royaltyReceiver, royalty);
    //         }

    //     } else {
    //         // collect
    //         k1155 = Katibeh1155(coll.addr);

    //         if(isPublic(katibeh.tags[0])){
    //             _fee = publicFee(k1155.totalSupply(coll.tokenId));
    //         } else {
    //             Pricing memory pricing = findPricing(katibeh);
    //             _fee = privateFee(k1155.totalSupply(coll.tokenId), amount, pricing);

    //             require(
    //                 block.timestamp <= pricing.expTime,
    //                 "Factory1155: token sale time is expired"
    //             );
    //         }
    //     }

    //     require(
    //         msg.value >= _fee,
    //         "Factory1155: insufficient Fee"
    //     );
    //     k1155.mint(collector, coll.tokenId, 1, "");
    //     _collectorScore[collector] ++;
    //     emit TransferSingle(address(this), address(0), collector, uint256(uint160(collector)), 1);
        
    //     if(data.length != 0) {
    //         emit TokenData(tokenHash, data);
    //     }

    //     if(msg.value > _fee) {
    //         payable(msg.sender).transfer(msg.value - _fee);
    //     }
    //     _payPublicFees(_fee, _getPayableOwner(katibeh.owners, katibeh.creator), dapps);
    // }

    function isPublic(bytes32 firstTag) internal pure returns(bool) {
        return firstTag[0] == 0x23;
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
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        require(isPublic(katibeh.tags[0]), "Factory1155: Only public collect allowed.");
        _checkFirstCollect(tokenHash, katibeh, sig);
        _checkToTokenHash(katibeh.toTokenHash);
        Katibeh1155 k1155 = Katibeh1155(_getCreateCollectionAddr(address(0), katibeh));
        uint96 tokenId = _getInitialTokenId(katibeh.signTime, k1155);
        address royaltyReceiver = _getPayableOwner(katibeh.owners, katibeh.creator);
        if(block.timestamp > katibeh.signTime + 1 days){
            initialSupply[address(k1155)][tokenId] = 1;
        }
        uint256 _fee = publicFee(0, amount, initialSupply[address(k1155)][tokenId]);
        _setTokenData(tokenHash, tokenId, 500, k1155, royaltyReceiver, katibeh);
        _collect(k1155, collector, tokenId, amount, data);
        // _payPublicFees(_fee, royaltyReceiver, dapps);
        _emitData(katibeh.data, tokenHash);
    }

    function firstPrivateCollect(
        address collector,
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        require(!isPublic(katibeh.tags[0]), "Factory1155: Only private collect allowed.");
        _checkFirstCollect(tokenHash, katibeh, sig);
        _checkToTokenHash(katibeh.toTokenHash);
        address collAddr = _getCreateCollectionAddr(katibeh.creator, katibeh);
        Katibeh1155 k1155 = Katibeh1155(collAddr);
        uint96 tokenId = _getInitialTokenId(katibeh.signTime, k1155);
        address royaltyReceiver = _getPayableOwner(katibeh.owners, katibeh.creator);
        Pricing memory pricing = findPricing(katibeh);
        _setPrivatePricing(pricing, Collection(collAddr, tokenId));
        _setTokenData(tokenHash, tokenId, pricing.royalty, k1155, royaltyReceiver, katibeh);
        _collect(k1155, collector, tokenId, amount, data);
        _payPrivateFees(privateFee(0, amount, pricing), pricing.discount,  royaltyReceiver, dapps);
        _emitData(katibeh.data, tokenHash);
    }

    // function publicCollect(
    //     Collection memory tokenInfo,
    //     address collector,
    //     uint256 amount,
    //     bytes calldata data,
    //     ISplitter.Share[] calldata dapps
    // ) public payable {
    //     Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);
    //     uint256 _fee = publicFee(k1155.totalSupply(tokenInfo.tokenId));
    //     _collect(k1155, collector, tokenInfo.tokenId, amount, data);
    //     (address royaltyReceiver,) = k1155.royaltyInfo(tokenInfo.tokenId, 0);
    //     _payPublicFees(_fee, royaltyReceiver, dapps);
    // }

    function privateCollect(
        uint256 tokenHash,
        address collector,
        uint256 amount,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        privateCollect(_tokenCollection[tokenHash], collector, amount, data, dapps);
    }

    function privateCollect(
        Collection memory tokenInfo,
        address collector,
        uint256 amount,
        bytes calldata data,
        ISplitter.Share[] calldata dapps
    ) public payable {
        Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);
        Pricing memory pricing = tokenPricing[tokenInfo.addr][tokenInfo.tokenId];
        uint256 _fee = privateFee(k1155.totalSupply(tokenInfo.tokenId), amount, pricing);
        _collect(k1155, collector, tokenInfo.tokenId, amount, data);
        (address royaltyReceiver,) = k1155.royaltyInfo(tokenInfo.tokenId, 0);
        _payPrivateFees(_fee, pricing.discount, royaltyReceiver, dapps);
    }

    // check if this is the first collect of the tokenHash.
    function _checkFirstCollect(uint256 tokenHash, Katibeh calldata katibeh, bytes calldata sig) internal view {
        require(_tokenCollection[tokenHash].addr == address(0), "Factory1155: This is not the first collect");
        require(
            sig.verify(
                katibeh.creator,
                getHash(katibeh)
            ),
            "Factory1155: Invalid signature"
        );
        require(
            QH.checkHash(sig, tokenHash),
            "Factory1155: wrong token id"
        );
        require(
            katibeh.signTime - 1 hours < block.timestamp &&
            katibeh.signTime > startTime,
            "Factory1155: wrong signTime"
        );
    }

    function _checkPrivateCollect(bytes32 firstTag, uint96 expTime) internal view {

    }

    function _checkToTokenHash(uint256[] calldata toTokenHash) internal view {
            uint256 len = toTokenHash.length;
            for(uint256 i; i < len; ++i) {
                address colAddr = _tokenCollection[toTokenHash[i]].addr;
                require(
                    colAddr != address(0) &&
                    Katibeh1155(colAddr).totalSupply(toTokenHash[i]) > 0,
                    "Factory1155: to token hash has not minted on current chain"
                );
            }
    }

    function _checkPublicCollect(Katibeh calldata katibeh, uint256 supply) internal view returns(uint256 _fee) {
    }

    function _setPrivatePricing(Pricing memory pricing, Collection memory coll) internal {
        require(
            block.timestamp >= pricing.initTime,
            "Factory1155: token sale time has not started yet"
        );        
        Pricing storage p = tokenPricing[coll.addr][coll.tokenId];
        p.A = pricing.A;
        p.B = pricing.B;
        p.C = pricing.C;
        p.D = pricing.D;
        p.totalSupply = pricing.totalSupply;
        p.expTime = pricing.expTime;
        p.discount = pricing.discount;
    }

    function _getCreateCollectionAddr(
        address originAddr, 
        Katibeh calldata katibeh
    ) internal returns(address collectionAddr) {
        Katibeh1155 k1155;
        collectionAddr = predictCollectionAddr(originAddr, katibeh.tags[0]);            
        k1155 = Katibeh1155(collectionAddr);
        if(collectionAddr.code.length == 0){
            address(implementation).cloneDeterministic(
                bytes32(abi.encodePacked(katibeh.creator, katibeh.tags[0]))
            );
            k1155.init(katibeh.creator, string(abi.encode(katibeh.tags[0])), "Katibeh");
        }
    }

    function _setTokenData(
        uint256 tokenHash,
        uint96 tokenId, 
        uint96 royalty,
        Katibeh1155 k1155,
        address royaltyReceiver,
        Katibeh calldata katibeh
    ) internal {
        _tokenCollection[tokenHash] = Collection(address(k1155), tokenId);
        k1155.setURI(tokenId, katibeh.tokenURI);
        _firstEmits(tokenHash, katibeh);
        k1155.setTokenRoyalty(tokenId, royaltyReceiver, royalty);
    }

    function _collect(Katibeh1155 k1155, address collector, uint256 tokenId, uint256 amount, bytes memory data) internal {
        k1155.mint(collector, tokenId, amount, data);
        _collectorScore[collector] += amount;
        emit TransferSingle(address(this), address(0), collector, uint256(uint160(collector)), 1);
    }

    function _emitData(bytes calldata data, uint256 tokenHash) internal {
        if(data.length != 0) {
            emit TokenData(tokenHash, data);
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

    function _getPayableOwners(
        ISplitter.Share[] memory owners, 
        address creator
    ) internal pure returns(ISplitter.Share[] memory ownersList) {
        uint256 len = owners.length;
        if(len == 0) {
            ownersList = new ISplitter.Share[](1);
            ownersList[0] = ISplitter.Share(payable(creator), 10000); // return the creator if there are no owners
        } else {
            return owners;
        }
    }
} 