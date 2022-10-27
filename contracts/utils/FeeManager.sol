// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract FeeManager {
    
    address payable receiver1;

    function _payFees(
        address creator,
        uint256 paidAmount,
        address[] calldata receivers, 
        uint16[] calldata fractions
    ) internal {
        _pay(creator, paidAmount * 70/100);
        _pay(receiver1, paidAmount * 3/100);

        require(
            receivers.length == fractions.length,
            "FeeManager: receivers and fractions must be the same length"
        );

        uint256 dappShare = paidAmount * 27/100;
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