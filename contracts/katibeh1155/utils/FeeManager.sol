// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./FeeUtils.sol";
import "../../splitter/interfaces/ISplitter.sol";


// poole hame usera ham bayad bere be addresse splittereshon

/**
 * @title FeeManager Contract
 * @dev An abstract contract that manages fees and payment distribution for Katibeh721 tokens.
 */
abstract contract FeeManager is FeeUtils {
    
    ISplitter public split;
    address payable receiver1; // Address of receiver1 for fee distribution
    uint256 constant baseFee = 10 ** 17; // Base fee amount in wei (0.1 ether)
    mapping(address => uint256) public userBalance;

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

    /**
     * @dev Internal function to pay fees and distribute payments to relevant parties.
     * @param paidAmount The total amount paid by the token buyer.
     * @param creator The address of the token creator.
     * @param owners An array of ISplitter.Share structs representing token owners.
     * @param dapps An array of ISplitter.Share structs representing Dapp owners.
     */
    function _payFees(
        uint256 paidAmount,
        address creator,
        ISplitter.Share[] memory owners,
        ISplitter.Share[] calldata dapps
    ) internal {
        uint256 receiver1Share = paidAmount * 20 / 1000; // 2% of the paid amount
        uint256 dappShare = paidAmount * 350 / 1000; // 35% of the paid amount

        _hold(receiver1, receiver1Share);

        uint256 len = dapps.length;
        uint256 denom = BASIS_POINTS;
        for(uint256 i; i < len; ++i) {
            _hold(dapps[i].recipient, dappShare * dapps[i].percentInBasisPoints / denom);
        }

        uint256 ownerShare = paidAmount - (receiver1Share + dappShare);
        len = owners.length;
        if(len == 0) {
            _pay(creator, ownerShare); // Pay the full amount to the creator if there are no owners
        } else {
            _pay(address(split.createSplit(owners)), ownerShare); // Pay the remaining balance to the last owner
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
        userBalance[receiver] += amount;
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
     * @return Pricing The pricing struct corresponding to the current chainId.
     */
    function findPricing(Katibeh memory katibeh) internal view returns(Pricing memory) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        uint256 len = katibeh.pricing.length;
        for(uint256 i; i < len; i++) {
            if(katibeh.pricing[i].chainId == chainId){
                return katibeh.pricing[i];
            }
        }
        return katibeh.pricing[0]; // Return the first pricing struct if the current chainId is not found
    }
}
