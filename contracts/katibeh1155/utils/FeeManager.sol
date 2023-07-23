// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../storage/DataStorage.sol";

abstract contract FeeManager is DataStorage {
    
    address payable receiver1;
    uint256 constant baseFee = 10 ** 17;

    function setReceiver1(address payable newAddr) public {
        require(
            msg.sender == receiver1,
            "FeeManager: only receiver1 can change its address"
        );
        receiver1 = newAddr;
    }

// receiver1 bayad 2 darsad begire o akhare kar harchi baqi moond ro daryaft mikone
    function _payFees(
        uint256 paidAmount,
        address creator,
        Payee[] memory owners,
        Payee[] calldata dapps
    ) internal {
        uint256 receiver1Share = paidAmount * 20/1000;
        uint256 dappShare = paidAmount * 350/1000;

        _pay(receiver1, receiver1Share);

        uint256 len = dapps.length;
        uint256 denom;
        for(uint256 i; i < len; ++i) {
            denom += dapps[i].share;
        }
        for(uint256 i; i < len; ++i) {
            _pay(dapps[i].addr, dappShare * dapps[i].share/denom);
        }

        uint256 ownerShare = address(this).balance;
        len = owners.length;
        if(len == 0) {
            _pay(creator, ownerShare);
        } else {
            denom = 0;
            for(uint256 i; i < len; ++i) {
                denom += owners[i].share;
            }
            for(uint256 i; i < len-1; ++i) {
                _pay(owners[i].addr, ownerShare * owners[i].share/denom);
            }
            _pay(owners[len-1].addr, address(this).balance);
        }
    }

    function _pay(address receiver, uint256 amount) internal {
        payable(receiver).transfer(amount);
    }
}