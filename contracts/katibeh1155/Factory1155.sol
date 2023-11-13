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
    
    /**
     * @dev Returns the initial token ID based on the given sign time and Katibeh1155 contract.
     * @param signTime The sign time used to calculate the initial token ID.
     * @param k1155 The Katibeh1155 contract instance.
     * @return tokenId The initial token ID.
     */
    function _getInitialTokenId(uint96 signTime, Katibeh1155 k1155) internal view returns (uint96 tokenId) {
        return k1155.getInitialId(signTime - startTime);
    }

    /**
     * @dev Returns the sign time for a given `tokenId`.
     * @param tokenId The token ID.
     * @return The sign time as a uint256 value.
     */
    function _getTokenSignTime(uint256 tokenId) internal view returns (uint256) {
        return tokenId + startTime;
    }
    
    /**
     * @dev Calculates fee and total supply for a token 
     * 
     * This function takes in the tokenHash, mint amount, and Katibeh data
     * to calculate the fee and current total supply for the token.
     * 
     * It first retrieves the token info struct mapped to the tokenHash.
     * 
     * It then checks if a valid contract address exists for the token.
     * If so, it gets a reference to the Katibeh1155 contract at that address.
     * 
     * Using the contract reference, it calls totalSupply() with the tokenId  
     * from the token info to get the current total supply.
     * 
     * The fee calculation occurs later based on supply, amount and Katibeh data.
     * 
     * @param tokenHash The unique hash identifying the token
     * @param amount The amount of tokens to mint  
     * @param katibeh The Katibeh data structure with pricing etc 
     * @return _fee The calculated fee for minting
     * @return supply The current total supply of the token
    */
    function feeAndSupply(
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh
    ) public view returns (uint256 _fee, uint256 supply) {
        Collection memory tokenInfo = _tokenCollection[tokenHash];
        Katibeh1155 k1155;
        // Check if a valid address exists for the given tokenHash
        if (tokenInfo.addr != address(0)) {
            k1155 = Katibeh1155(tokenInfo.addr);
            supply = k1155.totalSupply(tokenInfo.tokenId);
        }
        // get the public or private fee depending on the first tag in the katibeh struct is public or private
        if(isPublic(katibeh.tags[0])) {
            _fee = publicFee(supply, amount, initialSupply[address(k1155)][tokenInfo.tokenId]);
        } else {
            _fee = privateFee(supply, amount, findPricing(katibeh)); 
        }
    }

    /**
     * @dev Calculates the fee and current supply of a token.
     * @param tokenInfo The token information including the token address and ID.
     * @param amount The amount of tokens to be minted.
     * @return _fee The calculated fee for minting.
     * @return supply The current total supply of the token.
     */
    function feeAndSupply(
        Collection calldata tokenInfo,
        uint256 amount
    ) public view returns (uint256 _fee, uint256 supply) {
        Katibeh1155 k1155;
        k1155 = Katibeh1155(tokenInfo.addr);

        // Get the total supply of the token
        supply = k1155.totalSupply(tokenInfo.tokenId);

        // Check if the token is a public token
        if (isPublic((bytes32(bytes(k1155.name()))))) {
            // Calculate the fee using the publicFee function
            _fee = publicFee(supply, amount, initialSupply[address(k1155)][tokenInfo.tokenId]);
        } else {
            // Calculate the fee using the privateFee function and the pricing information from the tokenPricing mapping
            _fee = privateFee(supply, amount, tokenPricing[tokenInfo.addr][tokenInfo.tokenId]);
        }
    }

    /**
     * @dev Returns the URI for a given token hash.
     * @param tokenHash The token hash.
     * @return The URI as a string.
     */
    function uri(uint256 tokenHash) public view returns (string memory) {
        // Get the token information from the token collection mapping
        Collection memory tokenInfo = _tokenCollection[tokenHash];
        
        // Call the `uri` function of the Katibeh1155 contract with the token address and token ID
        return Katibeh1155(tokenInfo.addr).uri(tokenInfo.tokenId);
    }

    /**
     * @dev Returns the hash of the encoded `katibeh`.
     * @param katibeh The `Katibeh` struct.
     * @return The hash as a bytes32 value.
     */
    function getHash(Katibeh calldata katibeh) internal pure returns (bytes32) {
        return keccak256(abi.encode(katibeh));
    }

    /**
     * @dev Collects tokens to a specified collector address.
     * @param collector The address of the collector.
     * @param tokenInfo The token information.
     * @param amount The amount of tokens to collect.
     * @param data Additional data for the collect.
     * @param dapps The array of Dapps to distribute fees to.
     */
    function collectTo(
        address collector,
        Collection memory tokenInfo,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        // Create an instance of the Katibeh1155 contract using the token address from tokenInfo
        Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);
        
        if (isPublic(bytes32(bytes(k1155.name())))) {
            // If the token is public, call the publicCollect function
            publicCollect(tokenInfo, collector, amount, data, dapps);
        } else {
            // If the token is private, call the privateCollect function
            privateCollect(tokenInfo, collector, amount, data, dapps);
        }
    }

    /**
     * @dev Collects tokens to a specified collector address.
     * @param collector The address of the collector.
     * @param tokenHash The token hash.
     * @param amount The amount of tokens to collect.
     * @param katibeh The Katibeh struct containing token information.
     * @param sig The signature for the collect.
     * @param data Additional data for the collect.
     * @param dapps The array of Dapps to distribute fees to.
     */
    function collectTo(
        address collector,
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        // Get the token information from the token collection mapping
        Collection memory tokenInfo = _tokenCollection[tokenHash];
        
        if (tokenInfo.addr == address(0)) {
            // Token not found in the token collection, perform the first collect
            
            if (isPublic(katibeh.tags[0])) {
                // If the token is public, perform the first public collect
                firstPublicCollect(collector, tokenHash, amount, katibeh, sig, data, dapps);
            } else {
                // If the token is private, perform the first private collect
                firstPrivateCollect(collector, tokenHash, amount, katibeh, sig, data, dapps);
            }
        } else {
            // Token found in the token collection, perform the collect to the existing token
            
            // Call the `collectTo` function with the collector address, token information,
            // amount, data, and Dapps array
            collectTo(collector, tokenInfo, amount, data, dapps);
        }
    }

    function isPublic(bytes32 firstTag) internal pure returns(bool) {
        return firstTag[0] == 0xA4;
    }

    /**
     * @dev Predicts the address of a collection based on the creator address and tag0.
     * @param creatorAddr The address of the creator.
     * @param tag0 The first tag.
     * @return The predicted address of the collection.
     */
    function predictCollectionAddr(
        address creatorAddr,
        bytes32 tag0
    ) internal view returns (address) {
        // Encode the creator address and tag0 using abi.encodePacked
        bytes32 encodedData = bytes32(abi.encodePacked(creatorAddr, tag0));
        
        // Call the `predictDeterministicAddress` function of the implementation contract
        // with the encoded data and the address of this contract
        return address(implementation).predictDeterministicAddress(encodedData, address(this));
    }

    /**
     * @dev Performs the first public collect of tokens.
     * @param collector The address of the collector.
     * @param tokenHash The token hash.
     * @param amount The amount of tokens to collect.
     * @param katibeh The Katibeh struct containing token information.
     * @param sig The signature for the first collect.
     * @param data Additional data for the collect.
     * @param dapps The array of Dapps to distribute fees to.
     */
    function firstPublicCollect(
        address collector,
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        // Check if the token is available in the public collection
        require(isPublic(katibeh.tags[0]), "Factory1155: Only public collect allowed.");
        
        // Check the validity of the first collect signature
        _checkFirstCollect(tokenHash, katibeh, sig);
        
        // Check the validity of the toTokenHash
        _checkToTokenHash(katibeh.toTokenHash);
        
        // Get the address of the collection contract
        address collAddr = _getCreateCollectionAddr(address(0), katibeh);
        
        // Get the instance of the Katibeh1155 contract
        Katibeh1155 k1155 = Katibeh1155(collAddr);
        
        // Get the initial token ID based on the sign time
        uint96 tokenId = k1155.getInitialId(katibeh.signTime - startTime);
        
        // Get the royalty receiver address
        address royaltyReceiver = _getRoyaltyReceiver(katibeh.owners, katibeh.creator);
        
        // Calculate the fee for the public collect
        uint256 _fee = publicFee(0, amount, initialSupply[address(k1155)][tokenId]);
        
        // Update the initial supply if the sign time + 2 days has passed
        if (block.timestamp > katibeh.signTime + 2 days) {
            initialSupply[address(k1155)][tokenId] = amount;
        }
        
        // Create the token information
        Collection memory tokenInfo = Collection(collAddr, tokenId);
        
        // Update the token collection mapping with the token information
        _tokenCollection[tokenHash] = tokenInfo;
        
        // Set the token URI for the token
        k1155.setURI(tokenId, katibeh.tokenURI);
        
        // Set the token royalty for the token
        k1155.setTokenRoyalty(tokenId, royaltyReceiver, 500);
        
        // Emit the necessary events for the first collect
        _firstEmits(tokenHash, katibeh);
        
        // Perform the public collect
        _publicCollect(k1155, collector, tokenId, amount, fixedInterest(_fee), data);
        
        // Pay the public collection fees to the royalty receiver and Dapps
        _payPublicFees(_fee, royaltyReceiver, dapps);
        
        // Emit the necessary data
        _emitData(katibeh.data, tokenHash);
    }

    /**
     * @dev Performs the first private collect of tokens.
     * @param collector The address of the collector.
     * @param tokenHash The token hash.
     * @param amount The amount of tokens to collect.
     * @param katibeh The Katibeh struct containing token information.
     * @param sig The signature for the first collect.
     * @param data Additional data for the collect.
     * @param dapps The array of Dapps to distribute fees to.
     */
    function firstPrivateCollect(
        address collector,
        uint256 tokenHash,
        uint256 amount,
        Katibeh calldata katibeh,
        bytes calldata sig,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        // Check if the token is not available in the public collection
        require(!isPublic(katibeh.tags[0]), "Factory1155: Only private collect allowed.");
        
        // Check the validity of the first collect signature
        _checkFirstCollect(tokenHash, katibeh, sig);
        
        // Check the validity of the toTokenHash
        _checkToTokenHash(katibeh.toTokenHash);
        
        // Get the address of the collection contract
        address collAddr = _getCreateCollectionAddr(katibeh.creator, katibeh);
        
        // Get the instance of the Katibeh1155 contract
        Katibeh1155 k1155 = Katibeh1155(collAddr);
        
        // Get the initial token ID based on the sign time
        uint96 tokenId = k1155.getInitialId(katibeh.signTime - startTime);
        
        // Get the royalty receiver address
        address royaltyReceiver = _getRoyaltyReceiver(katibeh.owners, katibeh.creator);
        
        // Find the pricing information for the token
        Pricing memory pricing = findPricing(katibeh);
        
        // Create the token information
        Collection memory tokenInfo = Collection(collAddr, tokenId);
        
        // Set the private pricing for the token
        _setPrivatePricing(pricing, tokenInfo);
        
        // Update the token collection mapping with the token information
        _tokenCollection[tokenHash] = tokenInfo;
        
        // Set the token URI for the token
        k1155.setURI(tokenId, katibeh.tokenURI);
        
        // Set the token royalty for the token
        k1155.setTokenRoyalty(tokenId, royaltyReceiver, pricing.royalty);
        
        // Emit the necessary events for the first collect
        _firstEmits(tokenHash, katibeh);
        
        // Mint the tokens to the collector
        k1155.mint(collector, tokenId, amount, data);
        
        // Pay the private collection fees to the royalty receiver and Dapps
        _payPrivateFees(privateFee(0, amount, pricing), pricing.discount, royaltyReceiver, dapps);
        
        // Emit the necessary data
        _emitData(katibeh.data, tokenHash);
    }

    /**
     * @dev Performs a public collect of tokens.
     * @param tokenInfo The token information.
     * @param collector The address of the collector.
     * @param amount The amount of tokens to collect.
     * @param data Additional data for the collect.
     * @param dapps The array of Dapps to distribute fees to.
     */
    function publicCollect(
        Collection memory tokenInfo,
        address collector,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        // Get the instance of the Katibeh1155 contract
        Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);
        
        // Get the total supply of the token
        uint256 supply = k1155.totalSupply(tokenInfo.tokenId);
        
        // Check if the token is available in the public collection
        require(isPublic(bytes32(bytes(k1155.name()))), "Token is not available in public collection");
        
        // Update the initial supply if the token has not been signed and 2 days have passed
        if (block.timestamp > _getTokenSignTime(tokenInfo.tokenId) + 2 days &&
            initialSupply[address(k1155)][tokenInfo.tokenId] == 0) {
            initialSupply[address(k1155)][tokenInfo.tokenId] = supply;
        }
        
        // Calculate the fee for the public collect
        uint256 _fee = publicFee(supply, amount, initialSupply[address(k1155)][tokenInfo.tokenId]);
        
        // Perform the public collect
        _publicCollect(k1155, collector, tokenInfo.tokenId, amount, fixedInterest(_fee), data);
        
        // Get the royalty receiver address
        (address royaltyReceiver,) = k1155.royaltyInfo(tokenInfo.tokenId, 0);
        
        // Pay the public collection fees to the royalty receiver and Dapps
        _payPublicFees(_fee, royaltyReceiver, dapps);
    }

    /**
     * @dev Performs a private collect of tokens based on the token hash.
     * @param tokenHash The token hash.
     * @param collector The address of the collector.
     * @param amount The amount of tokens to collect.
     * @param data Additional data for the collect.
     * @param dapps The array of Dapps to distribute fees to.
     */
    function privateCollect(
        uint256 tokenHash,
        address collector,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        privateCollect(_tokenCollection[tokenHash], collector, amount, data, dapps);
    }

    /**
     * @dev Performs a private collect of tokens.
     * @param tokenInfo The token information.
     * @param collector The address of the collector.
     * @param amount The amount of tokens to collect.
     * @param data Additional data for the collect.
     * @param dapps The array of Dapps to distribute fees to.
     */
    function privateCollect(
        Collection memory tokenInfo,
        address collector,
        uint256 amount,
        bytes calldata data,
        SplitterForOwners.Share[] calldata dapps
    ) public payable {
        // Get the instance of the Katibeh1155 contract
        Katibeh1155 k1155 = Katibeh1155(tokenInfo.addr);

        // Get the pricing information for the token
        Pricing memory pricing = tokenPricing[tokenInfo.addr][tokenInfo.tokenId];

        // Check if the token is available in the private collection
        require(!isPublic(bytes32(bytes(k1155.name()))), "Token is not available in private collection");

        // Calculate the fee for the private collect
        uint256 _fee = privateFee(k1155.totalSupply(tokenInfo.tokenId), amount, pricing);

        // Mint the tokens to the collector
        k1155.mint(collector, tokenInfo.tokenId, amount, data);

        // Get the royalty receiver address
        (address royaltyReceiver,) = k1155.royaltyInfo(tokenInfo.tokenId, 0);

        // Pay the private collection fees to the royalty receiver and Dapps
        _payPrivateFees(_fee, pricing.discount, royaltyReceiver, dapps);
    }

    /**
     * @dev Withdraws the balance for the specified token.
     * @param tokenInfo The token information.
     */
    function withdraw(Collection memory tokenInfo) public {
        (address royaltyReceiver,) = Katibeh1155(tokenInfo.addr).royaltyInfo(tokenInfo.tokenId, 0);
        uint256 balance = userBalance[royaltyReceiver];
        delete userBalance[royaltyReceiver];
        _pay(royaltyReceiver, balance);
    }

    /**
     * @dev Internal function to check if this is the first collect of the tokenHash.
     * @param tokenHash The token hash to check.
     * @param katibeh The data for the token.
     * @param sig The signature to verify.
     */
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

    /**
     * @dev Internal function to check if the to token hashes have been minted on the current chain.
     * @param toTokenHash The array of to token hashes to check.
     */
    function _checkToTokenHash(uint256[] calldata toTokenHash) internal view {
        uint256 len = toTokenHash.length;
        for(uint256 i; i < len; ++i) {
            address colAddr = _tokenCollection[toTokenHash[i]].addr;
            require(
                colAddr != address(0) &&
                Katibeh1155(colAddr).totalSupply(toTokenHash[i]) > 0,
                "Factory1155: to token hash has not been minted on the current chain"
            );
        }
    }

    /**
     * @dev Internal function to set the private pricing for a token.
     * @param pricing The pricing information.
     * @param tokenInfo The token information.
     */
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

    /**
     * @dev Internal function to get or create the collection address for a token.
     * @param originAddr The address of the origin token.
     * @param katibeh The Katibeh struct representing the token.
     * @return collectionAddr The address of the collection contract.
     */
    function _getCreateCollectionAddr(
        address originAddr, 
        Katibeh calldata katibeh
    ) internal returns(address collectionAddr) {
        Katibeh1155 k1155;
        collectionAddr = predictCollectionAddr(originAddr, katibeh.tags[0]);

        // Check if the collection address already exists
        k1155 = Katibeh1155(collectionAddr);
        if(collectionAddr.code.length == 0) {
            // Create a new collection address if it doesn't exist
            address(implementation).cloneDeterministic(
                bytes32(abi.encodePacked(katibeh.creator, katibeh.tags[0]))
            );
            string memory symb = originAddr == address(0) ? unicode"¤" : "KATIBEH";
            k1155.init(katibeh.creator, string(abi.encode(katibeh.tags[0])), symb);
        }
    }

    /**
     * @dev Internal function to set the data for a token.
     * @param tokenHash The hash of the token.
     * @param tokenId The ID of the token.
     * @param royalty The royalty value for the token.
     * @param k1155 The instance of the Katibeh1155 contract.
     * @param royaltyReceiver The address of the royalty receiver.
     * @param katibeh The data for the token.
     */
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

    /**
     * @dev Internal function to handle the minting of tokens and emit the corresponding events.
     * @param k1155 The instance of the Katibeh1155 contract.
     * @param collector The address of the token collector.
     * @param tokenId The ID of the token to be minted.
     * @param amount The amount of tokens to be minted.
     * @param value The value associated with the minted tokens.
     * @param data Additional data to be passed along with the minted tokens.
     */
    function _publicCollect(
        Katibeh1155 k1155,
        address collector,
        uint256 tokenId,
        uint256 amount,
        uint256 value,
        bytes memory data
    ) internal {
        uint256[] memory tokenIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        (tokenIds[0], tokenIds[1]) = (tokenId, 0);
        (amounts[0], amounts[1]) = (amount, value);

        k1155.mintBatch(collector, tokenIds, amounts, data);
    }

    /**
     * @dev Calculates the fixed interest amount based on a given value.
     * @param value The value for which to calculate the fixed interest.
     * @return amount The calculated fixed interest amount.
     */
    function fixedInterest(uint256 value) public view returns (uint256 amount){
        return value / ((block.timestamp - startTime + 365 days) * 100000000 / 365 days);
    }

    /**
     * @dev Internal function to emit token data if provided.
     * @param data The data to be emitted.
     * @param tokenHash The hash of the token.
     */
    function _emitData(bytes calldata data, uint256 tokenHash) internal {
        if(data.length != 0) {
            emit TokenData(tokenHash, data);
        }
    }

    /**
     * @dev Internal function to get the royalty receiver address.
     * @param owners The array of owners and their corresponding shares.
     * @param creator The address of the creator.
     * @return The address of the royalty receiver.
     */
    function _getRoyaltyReceiver(SplitterForOwners.Share[] memory owners, address creator) internal returns(address) {
        uint256 len = owners.length;
        if(len == 0) {
            return creator; // return the creator if there are no owners
        } else if(len == 1) {
            return owners[0].recipient;
        } else {
            return address(split.createSplit(owners)); // return the splitter for specified owners.
        }
    }
} 