// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

interface ISplitter {

  struct Share {
    address payable recipient;
    uint256 percentInBasisPoints;
  }

  function createSplit(ISplitter.Share[] memory shares) external returns (ISplitter splitInstance);
  function getPredictedSplitAddress(ISplitter.Share[] memory shares) external view returns (address);

}