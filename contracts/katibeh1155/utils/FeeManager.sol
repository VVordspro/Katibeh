// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./FeeUtils.sol";


/**
 * @title FeeManager Contract
 * @dev An abstract contract that manages fees and payment distribution for Katibeh721 tokens.
 */
abstract contract FeeManager is FeeUtils {
    
    SplitterForOwners public split;
    address payable receiver1; // Address of receiver1 for fee distribution
    uint256 constant baseFee = 10 ** 17; // Base fee amount in wei (0.1 ether)
    uint256 constant BASIS_POINTS = 10 **6;
    uint256 public totalValueLocked;
    mapping(address => uint256) public userBalance;
    mapping(address => mapping(uint96 => uint256)) public tokenValueLocked;
    mapping(address => mapping(uint96 => Pricing)) public tokenPricing;

    constructor() {
        split = new SplitterForOwners(address(this));
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

    /**
     * @dev Collects and distributes public fees.
     * @param lockFee The amount of fees to be collected.
     * @param royaltyReceiver The address of the royalty receiver.
     * @param dapps The array of dapps and their respective shares.
     */
    function _payPublicFees(
        Collection memory tokenInfo,
        uint256 lockFee,
        address royaltyReceiver,
        uint64 creatorShare,
        SplitterForOwners.Share[] calldata dapps,
        ReplyCollection[] memory replyCollections
    ) internal {
        uint256 feeAmount = lockFee * 101/100 + lockFee * creatorShare/BASIS_POINTS;
        require(
            msg.value >= feeAmount,
            "FeeManager: insufficient Fee"
        );
        unchecked{
            tokenValueLocked[tokenInfo.addr][tokenInfo.tokenId] += lockFee;
        }

        uint256 otherFee = feeAmount - lockFee;

        // dev payment
        uint256 devShare = otherFee / 5;
        uint256 len = dapps.length;
        uint256 totalShare;
        if(len > 0) {
            for(uint256 i; i < len; ++i) {
                totalShare += dapps[i].percentInBasisPoints;
            }
            for(uint256 i; i < len; ++i) {
                // Calculate and hold the share for each dapp recipient
                _hold(dapps[i].recipient, devShare * dapps[i].percentInBasisPoints / totalShare);
            }
        } else {
            devShare = 0;
        }

        // creator payment
        uint256 creatorShare = otherFee / 5;
        _hold(royaltyReceiver, creatorShare);

        // contract payment
        uint256 contractShare = otherFee / 5;
        unchecked{
            tokenValueLocked[tokenInfo.addr][0] += contractShare;
        }

        // reply payment
        uint256 repliesShare = otherFee / 5;
        uint256 replyShare;
        len = replyCollections.length;
        int256 total;
        for(uint256 i; i < len; i++) {
            if(replyCollections[i].value >= 0) {
                total += replyCollections[i].value;
                replyShare = repliesShare * uint16(replyCollections[i].value) / basisPoint;
                addValue(replyCollections[i].addr, replyCollections[i].tokenId, replyShare);
            } else {
                total -= replyCollections[i].value;
                replyShare = repliesShare * uint16(-replyCollections[i].value) / basisPoint;
                removeValue(replyCollections[i].addr, replyCollections[i].tokenId, replyShare);
            }
        }


        if(msg.value > feeAmount) {
            // Pay back the excess amount to the msg.sender
            _pay(msg.sender, msg.value - feeAmount);
        }
        unchecked{
            // Update the totalValueLocked
            totalValueLocked += devShare;
        }
    }

    /**
     * @dev Internal function to pay fees and distribute payments to relevant parties.
     * @param feeAmount The total amount paid by the token buyer.
     * @param discount The discount percentage applied to the feeAmount.
     * @param royaltyReceiver The payable owner to receive collect fee.
     * @param dapps An array of SplitterForOwners.Share structs representing Dapp owners.
     */
    function _payPrivateFees(
        uint256 feeAmount,
        uint96 discount,
        address royaltyReceiver,
        SplitterForOwners.Share[] calldata dapps
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
                // Calculate the dappShare based on the discount percentage
                dappShare = feeAmount * discount / 10000;

                uint256 len = dapps.length;
                uint256 totalShare;
                for(uint256 i; i < len; ++i) {
                    totalShare += dapps[i].percentInBasisPoints;
                }
                for(uint256 i; i < len; ++i) {
                    // Hold the dappShare for each dapp recipient
                    _hold(dapps[i].recipient, dappShare * dapps[i].percentInBasisPoints / totalShare);
                }
                unchecked{
                    // Update the totalValueLocked
                    totalValueLocked += dappShare;
                }
            }
            // Pay the remaining feeAmount to the royaltyReceiver
            _pay(royaltyReceiver, feeAmount - dappShare);
        }
        if(msg.value > feeAmount) {
            // Pay back the excess amount to the msg.sender
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

    /**
     * @dev Withdraws the balance of the caller's account.
     * The balance is transferred to the caller's address.
     */
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

        // Get the length of the pricing array
        uint256 len = katibeh.pricing.length;

        if (len > 0) {
            // Iterate through the pricing array to find a matching chainId
            for (uint256 i; i < len; i++) {
                if (katibeh.pricing[i].chainId == chainId) {
                    // Return the pricing struct for the matching chainId
                    return katibeh.pricing[i];
                }
            }

            // If no matching chainId is found, fall back to chainId 0
            for (uint256 i; i < len; i++) {
                if (katibeh.pricing[i].chainId == 0) {
                    return katibeh.pricing[i];
                }
            }

            // If no pricing struct is found, revert with an error message
            revert("FeeManager: Pricing is not set on this chainId.");
        } else {
            // If no pricing struct is found, revert with an error message
            revert("FeeManager: Pricing is not set.");
        }
    }
}
