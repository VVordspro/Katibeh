// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./FeeUtils.sol";
import "../../splitter/interfaces/ISplitter.sol";


/**
 * @title FeeManager Contract
 * @dev An abstract contract that manages fees and payment distribution for Katibeh721 tokens.
 */
abstract contract FeeManager is FeeUtils {
    
    ISplitter public split;
    address payable receiver1; // Address of receiver1 for fee distribution
    uint256 constant baseFee = 10 ** 17; // Base fee amount in wei (0.1 ether)
    uint256 public totalValueLocked;
    mapping(address => uint256) public userBalance;
    mapping(address => mapping(uint96 => Pricing)) public tokenPricing;

    constructor(ISplitter _split) {
        split = _split;
    }

    /**
     * @dev Set the address of receiver1.
     * @param newAddr The new address of receiver1.
     */
    function setReceiver1(address payable newAddr) public {
        require(
            msg.sender == receiver1,
            "FeeManager: Only receiver1 can change its address"
        );
        receiver1 = newAddr;
    }

    function _payPublicFees(
        uint256 feeAmount,
        ISplitter.Share[] calldata owners,
        ISplitter.Share[] calldata dapps
    ) internal {
        require(
            msg.value >= feeAmount,
            "FeeManager: insufficient Fee"
        );
        uint256 devShare = feeAmount * 95 / 100000;

        uint256 len = dapps.length;
        uint256 denom = BASIS_POINTS;
        uint256 totalShare;
        for(uint256 i; i < len; ++i) {
            totalShare += dapps[i].percentInBasisPoints;
            _hold(dapps[i].recipient, devShare * dapps[i].percentInBasisPoints / denom);
        }
        for(uint256 i; i < len; ++i) {
            _hold(owners[i].recipient, devShare * owners[i].percentInBasisPoints / denom);
        }
        require(totalShare == denom, "FeeManager: The sum of Dapp percentInBasisPoints must equal 10000");

        if(msg.value > feeAmount) {
            _pay(msg.sender, msg.value - feeAmount);
        }
        unchecked{
            totalValueLocked += devShare;
        }
    }

    /**
     * @dev Internal function to pay fees and distribute payments to relevant parties.
     * @param feeAmount The total amount paid by the token buyer.
     * @param owner the payable owner to receive collect fee.
     * @param dapps An array of ISplitter.Share structs representing Dapp owners.
     */
    function _payPrivateFees(
        uint256 feeAmount,
        uint96 discount,
        address owner,
        ISplitter.Share[] calldata dapps
    ) internal {
        require(
            msg.value >= feeAmount,
            "FeeManager: insufficient Fee"
        );
        if(feeAmount > 0){
            require(
                discount <= 10000,
                "FeeManager: Maximum discount is 100%"
            );
            uint256 dappShare;
            if(discount > 0){
                dappShare = feeAmount * discount / 10000;

                uint256 len = dapps.length;
                uint256 denom = BASIS_POINTS;
                uint256 totalShare;
                for(uint256 i; i < len; ++i) {
                    totalShare += dapps[i].percentInBasisPoints;
                    _hold(dapps[i].recipient, dappShare * dapps[i].percentInBasisPoints / denom);
                }
                require(totalShare == denom, "FeeManager: The sum of Dapp percentInBasisPoints must equal 10000");
                unchecked{
                    totalValueLocked += dappShare;
                }
            }
            _pay(owner, feeAmount - dappShare);
        }
        if(msg.value > feeAmount) {
            _pay(msg.sender, msg.value - feeAmount);
        }
    }

    /**
     * @dev Internal function to transfer funds to a specific receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be transferred.
     */
    function _pay(address receiver, uint256 amount) internal returns(bool success){
        (success,) = payable(receiver).call{value : amount}("");
    }

    /**
     * @dev Internal function to transfer funds to a specific receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be transferred.
     */
    function _hold(address receiver, uint256 amount) internal {
        unchecked {
            userBalance[receiver] += amount;
        }
    }

    function withdraw() public {
        address userAddr = msg.sender;
        uint256 balance = userBalance[userAddr];
        delete userBalance[userAddr];
        _pay(userAddr, balance);
    }

    /**
     * @dev Internal function to find the pricing for a token based on the current chainId.
     * @param katibeh The Katibeh struct representing the token.
     * @return p Pricing The pricing struct corresponding to the current chainId.
     */
    function findPricing(Katibeh memory katibeh) internal view returns(Pricing memory p) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        uint256 len = katibeh.pricing.length;
        if(len > 0){
            for(uint256 i; i < len; i++) {
                if(katibeh.pricing[i].chainId == chainId){
                    return katibeh.pricing[i];
                }
            }
            for(uint256 i; i < len; i++) {
                if(katibeh.pricing[i].chainId == 0){
                    return katibeh.pricing[i];
                }
            }
            revert("FeeManager: Pricing is not set on this chainId.");
        } else {
            revert("FeeManager: Pricing is not set.");
        }
    }
}
