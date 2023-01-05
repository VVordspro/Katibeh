// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../utils/DataStorage.sol";

abstract contract FeeManager is DataStorage {
    
    address payable receiver1;
    uint256 constant baseFee = 10 ** 18;

    function setReceiver1(address payable newAddr) public {
        require(
            msg.sender == receiver1,
            "FeeManager: only receiver1 can change its address"
        );
        receiver1 = newAddr;
    }

    function _payFees(
        uint256 paidAmount,
        Payee[] memory owners,
        Payee[] calldata dapps
    ) internal {
        _pay(receiver1, paidAmount * 25/1000);

        uint256 dappShare = paidAmount * 750/1000;
        uint256 ownerShare = paidAmount - (paidAmount * 25/1000 + paidAmount * 750/1000);
        
        uint256 len = owners.length;
        uint256 totalFractions;

        for(uint256 i; i < len; i++) {
            totalFractions += owners[i].share;
            _pay(owners[i].addr, ownerShare * owners[i].share/10000);
        }

        len = dapps.length;
        totalFractions = 0;
        for(uint256 i; i < len; i++) {
            totalFractions += dapps[i].share;
            _pay(dapps[i].addr, dappShare * dapps[i].share/10000);
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