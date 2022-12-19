// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract FeeManager {
    
    address payable receiver1;
    function setReceiver1(address payable newAddr) public {
        require(
            msg.sender == receiver1,
            "FeeManager: only receiver1 can change its address"
        );
        receiver1 = newAddr;
    }

    function _payFees(
        address creator,
        uint256 paidAmount,
        address[] calldata receivers, 
        uint16[] calldata fractions
    ) internal {
        _pay(creator, paidAmount * 750/1000);
        _pay(receiver1, paidAmount * 25/1000);

        require(
            receivers.length == fractions.length,
            "FeeManager: receivers and fractions must be the same length"
        );

        uint256 dappShare = paidAmount - (paidAmount * 25/1000 + paidAmount * 750/1000);
        
        uint16 totalFractions;
        for(uint8 i; i < fractions.length; i++) {
            totalFractions += fractions[i];
            _pay(receivers[i], dappShare * fractions[i]/10000);
        }

        require(
            totalFractions == 10000, 
            "FeeManager: total fractions number must equal 10000"
        );
    }

    function _pay(address receiver, uint256 amount) internal {
        payable(receiver).transfer(amount);
    }
}