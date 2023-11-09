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
    mapping(address => mapping(uint96 => SplitterForOwners.Share[])) tokenOwners;

    Katibeh1155 immutable public implementation;
    IQHash public QH;
    uint96 public startTime;

    event TokenData(uint256 indexed tokenHash, bytes data);

    constructor(address qhAddr, uint96 _startTime) {
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

    function _getTokenSignTime(uint256 tokenId) internal view returns(uint256) {
        return tokenId + startTime;
    }
    
    function feeAndSupply(
        uint256 tokenHash, 
        uint256 amount,
        Katibeh calldata katibeh
    ) public view returns(
        uint256 _fee, 
        uint256 supply
    ) {
        Collection memory tokenInfo = _tokenCollection[tokenHash];
        Katibeh1155 k1155;
        if(tokenInfo.addr != address(0)){
            k1155 = Katibeh1155(tokenInfo.addr);
            supply = k1155.totalSupply(tokenInfo.tokenId);
        }
        if(isPublic(katibeh.tags[0])) {
            _fee = publicFee(supply, amount, initialSupply[address(k1155)][tokenInfo.tokenId]);
        } else {
            _fee = privateFee(supply, amount, findPricing(katibeh));
        }
    }
    
    function feeAndSupply(
        Collection calldata tokenInfo, 
        uint256 amount
    ) public view returns(
        uint256 _fee, 
        uint256 supply
    ) {
        Katibeh1155 k1155;
        k1155 = Katibeh1155(tokenInfo.addr);
        supply = k1155.totalSupply(tokenInfo.tokenId);
        if(isPublic((bytes32(bytes(k1155.name()))))) {
            _fee = publicFee(supply, amount, initialSupply[address(k1155)][tokenInfo.tokenId]);
        } else {
            _fee = privateFee(supply, amount, tokenPricing[tokenInfo.addr][tokenInfo.tokenId]);
        }
    }

    function uri(uint256 tokenHash) public view returns(string memory) {

        address addr = address(uint160(tokenHash));
        if(_collectorScore[addr] != 0) {
            return 'data:application/json;base64,eyJuYW1lIjogIkthdGliZWgiLCJkZXNjcmlwdGlvbiI6ICJOb24tdHJhbnNmZXJhYmxlIiwiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTlRZM0lpQm9aV2xuYUhROUlqVTJOeUlnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4ZEdWNGRDQjRQU0kxTUNVaUlIazlJamN3SlNJZ2RHVjRkQzFoYm1Ob2IzSTlJbTFwWkdSc1pTSStTMkYwYVdKbGFEd3ZkR1Y0ZEQ0OEwzTjJaejQ9In0=';
        }
        Collection memory tokenInfo = _tokenCollection[tokenHash];
        return Katibeh1155(tokenInfo.addr).uri(tokenInfo.tokenId);
    }

    function getHash(Katibeh calldata katibeh) internal pure returns(bytes32) {
        return keccak256(abi.encode(katibeh));
    }

    function collectTo(
        address collector,
        Collection memory tokenInfo,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);
        if(isPublic((bytes32(bytes(k1155.name()))))){
            publicCollect(tokenInfo, collector, amount, data, dapps);
        } else {
            privateCollect(tokenInfo, collector, amount, data, dapps);
        }
    }

    function collectTo(
        address collector,
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        Collection memory tokenInfo = _tokenCollection[tokenHash];

        if(tokenInfo.addr == address(0)) {
            // first collect
            if(isPublic(katibeh.tags[0])){
                firstPublicCollect(collector, tokenHash, amount, katibeh, sig, data, dapps);
            } else {
                firstPrivateCollect(collector, tokenHash, amount, katibeh, sig, data, dapps);
            }
        } else {
            collectTo(collector, tokenInfo, amount, data, dapps);
        }
    }

    function isPublic(bytes32 firstTag) internal pure returns(bool) {
        return firstTag[0] == 0xA4;
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
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        require(isPublic(katibeh.tags[0]), "Factory1155: Only public collect allowed.");
        _checkFirstCollect(tokenHash, katibeh, sig);
        _checkToTokenHash(katibeh.toTokenHash);
        address collAddr = _getCreateCollectionAddr(address(0), katibeh);
        Katibeh1155 k1155 = Katibeh1155(collAddr);
        uint96 tokenId = k1155.getInitialId(katibeh.signTime - startTime);
        address royaltyReceiver = _getPayableOwner(katibeh.owners, katibeh.creator);
        uint256 _fee = publicFee(0, amount, initialSupply[address(k1155)][tokenId]);
        if(block.timestamp > katibeh.signTime + 2 days){
            initialSupply[address(k1155)][tokenId] = amount;
        }
        Collection memory tokenInfo = Collection(collAddr, tokenId);
        _tokenCollection[tokenHash] = tokenInfo;
        k1155.setURI(tokenId, katibeh.tokenURI);
        k1155.setTokenRoyalty(tokenId, royaltyReceiver, 500);
        _firstEmits(tokenHash, katibeh);
        _publicCollect(k1155, collector, tokenId, amount, fixedInterest(_fee), data);
        _payPublicFees(_fee, royaltyReceiver, dapps);
        _emitData(katibeh.data, tokenHash);
    }

    function firstPrivateCollect(
        address collector,
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        require(!isPublic(katibeh.tags[0]), "Factory1155: Only private collect allowed.");
        _checkFirstCollect(tokenHash, katibeh, sig);
        _checkToTokenHash(katibeh.toTokenHash);
        address collAddr = _getCreateCollectionAddr(katibeh.creator, katibeh);
        Katibeh1155 k1155 = Katibeh1155(collAddr);
        uint96 tokenId = k1155.getInitialId(katibeh.signTime - startTime);
        address royaltyReceiver = _getPayableOwner(katibeh.owners, katibeh.creator);
        Pricing memory pricing = findPricing(katibeh);
        Collection memory tokenInfo = Collection(collAddr, tokenId);
        _setPrivatePricing(pricing, tokenInfo);
        _tokenCollection[tokenHash] = tokenInfo;
        k1155.setURI(tokenId, katibeh.tokenURI);
        k1155.setTokenRoyalty(tokenId, royaltyReceiver, pricing.royalty);
        _firstEmits(tokenHash, katibeh);
        k1155.mint(collector, tokenId, amount, data);
        _payPrivateFees(privateFee(0, amount, pricing), pricing.discount,  royaltyReceiver, dapps);
        _emitData(katibeh.data, tokenHash);
    }

    function publicCollect(
        Collection memory tokenInfo,
        address collector,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);
        uint256 supply = k1155.totalSupply(tokenInfo.tokenId);
        require(isPublic(bytes32(bytes(k1155.name()))), "Token is not available in public collection");
        if(
            block.timestamp > _getTokenSignTime(tokenInfo.tokenId) + 2 days &&
            initialSupply[address(k1155)][tokenInfo.tokenId] == 0
        ){
            initialSupply[address(k1155)][tokenInfo.tokenId] = supply;
        }
        uint256 _fee = publicFee(
            supply, 
            amount, 
            initialSupply[address(k1155)][tokenInfo.tokenId]
        );
        _publicCollect(k1155, collector, tokenInfo.tokenId, amount, fixedInterest(_fee), data);
        (address royaltyReceiver,) = k1155.royaltyInfo(tokenInfo.tokenId, 0);
        _payPublicFees(_fee, royaltyReceiver, dapps);

    }

    function privateCollect(
        uint256 tokenHash,
        address collector,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        privateCollect(_tokenCollection[tokenHash], collector, amount, data, dapps);
    }

    function privateCollect(
        Collection memory tokenInfo,
        address collector,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);
        Pricing memory pricing = tokenPricing[tokenInfo.addr][tokenInfo.tokenId];
        require(!isPublic(bytes32(bytes(k1155.name()))), "Token is not available in private collection");
        uint256 _fee = privateFee(k1155.totalSupply(tokenInfo.tokenId), amount, pricing);
        k1155.mint(collector, tokenInfo.tokenId, amount, data);
        (address royaltyReceiver,) = k1155.royaltyInfo(tokenInfo.tokenId, 0);
        _payPrivateFees(_fee, pricing.discount, royaltyReceiver, dapps);
    }

    function withdraw(Collection memory tokenInfo) public {
        (address royaltyReceiver,) = Katibeh1155(tokenInfo.addr).royaltyInfo(tokenInfo.tokenId, 0);
        uint256 balance = userBalance[royaltyReceiver];
        delete userBalance[royaltyReceiver];
        _pay(royaltyReceiver, balance);
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

    function _setPrivatePricing(Pricing memory pricing, Collection memory tokenInfo) internal {
        require(
            block.timestamp >= pricing.initTime,
            "Factory1155: token sale time has not started yet"
        );        
        Pricing storage p = tokenPricing[tokenInfo.addr][tokenInfo.tokenId];
        p.A = pricing.A;
        p.B = pricing.B;
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
            string memory symb = originAddr == address(0) ? unicode"¤" : "KATIBEH";
            k1155.init(katibeh.creator, string(abi.encode(katibeh.tags[0])), symb);
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

    function _publicCollect(Katibeh1155 k1155, address collector, uint256 tokenId, uint256 amount, uint256 value, bytes memory data) internal {
        uint256[] memory tokenIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        (tokenIds[0], tokenIds[1]) = (tokenId, 0);
        (amounts[0], amounts[1]) = (amount, value);

        k1155.mintBatch(collector, tokenIds, amounts, data);
    }

    function fixedInterest(uint256 value) public view returns (uint256 amount){
        return value / ((block.timestamp - startTime + 365 days) * 100000000 / 365 days);
    }

    function _emitData(bytes calldata data, uint256 tokenHash) internal {
        if(data.length != 0) {
            emit TokenData(tokenHash, data);
        }
    }

    function _getPayableOwner(SplitterForOwners.Share[] memory owners, address creator) internal returns(address) {
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
        SplitterForOwners.Share[] memory owners, 
        address creator
    ) internal pure returns(SplitterForOwners.Share[] memory ownersList) {
        uint256 len = owners.length;
        if(len == 0) {
            ownersList = new SplitterForOwners.Share[](1);
            ownersList[0] = SplitterForOwners.Share(payable(creator), 10000); // return the creator if there are no owners
        } else {
            return owners;
        }
    }
} 