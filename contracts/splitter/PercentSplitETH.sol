/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Approve.sol";
import "./libraries/BytesLibrary.sol";

/**
 * @notice Deploys contracts which auto-forwards any ETH sent to it to a list of recipients
 * considering their percent share of the payment received.
 * @dev Uses create2 counterfactual addresses so that the destination is known from the terms of the split.
 */
contract SplitterForOwners is Initializable {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;
  using BytesLibrary for bytes;
  using SafeMath for uint256;

  struct Share {
    address payable recipient;
    uint96 percentInBasisPoints;
  }

  uint96 internal BASIS_POINTS;
  address public immutable FACTORY;

  Share[] private _shares;

  event PercentSplitCreated(address indexed contractAddress);
  event PercentSplitShare(address indexed recipient, uint256 percentInBasisPoints);
  event ETHTransferred(address indexed account, uint256 amount);
  event ERC20Transferred(address indexed erc20Contract, address indexed account, uint256 amount);

  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

  /**
   * @dev Requires that the msg.sender is one of the recipients in this split.
   */
  modifier onlyRecipient() {
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i].recipient == msg.sender) {
        _;
        return;
      }
    }
    revert("Split: Can only be called by one of the recipients");
  }

  constructor(address factory) {
    FACTORY = factory;
  }

  /**
   * @notice Returns the ETH balance of this splitter in the KATIBEH factory.
   */
  function balanceETH() external view returns(uint256) {
    (, bytes memory data) = FACTORY.staticcall(abi.encodeWithSignature("userBalance(address)", address(this)));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Withdraw the ETH balance of this splitter in the KATIBEH factory and split it to the members.
   */
  function withdraw() external {
    (bool success,) = FACTORY.call(abi.encodeWithSignature("withdraw()"));
    require(success, "Unable to withdraw");
  }

  function uri(uint256 id) external pure returns (string memory){
    require(id == 0);
    return "data:application/json;base64,eyJuYW1lIjoiS2F0aWJlaCBTcGxpdHRlciIsImRlc2NyaXB0aW9uIjoiVGhpcyBDb250cmFjdCBTcGxpdCB5b3VyIEZ1bmRzIHdoaXQgWW91ciBzaGFyZSBIb2xkZWVycy4iLCJpbWFnZSI6ImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTVRZdU1EQWdNVFl1TURBaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJZ1ptbHNiRDBpSXpBd01EQXdNQ0lnWTJ4aGMzTTlJbUpwSUdKcExYTnBaMjV3YjNOMExYTndiR2wwSWlCMGNtRnVjMlp2Y20wOUltMWhkSEpwZUNneExDQXdMQ0F3TENBeExDQXdMQ0F3S1NJZ2MzUnliMnRsUFNJak1EQXdNREF3SWlCemRISnZhMlV0ZDJsa2RHZzlJakF1TURBd01UWWlQanhuSUdsa1BTSlRWa2RTWlhCdlgySm5RMkZ5Y21sbGNpSWdjM1J5YjJ0bExYZHBaSFJvUFNJd0lqNDhMMmMrUEdjZ2FXUTlJbE5XUjFKbGNHOWZkSEpoWTJWeVEyRnljbWxsY2lJZ2MzUnliMnRsTFd4cGJtVmpZWEE5SW5KdmRXNWtJaUJ6ZEhKdmEyVXRiR2x1WldwdmFXNDlJbkp2ZFc1a0lpQnpkSEp2YTJVOUlpTkRRME5EUTBNaUlITjBjbTlyWlMxM2FXUjBhRDBpTUM0eU9EZ2lQand2Wno0OFp5QnBaRDBpVTFaSFVtVndiMTlwWTI5dVEyRnljbWxsY2lJK0lEeHdZWFJvSUdROUlrMDNJRGRXTVM0ME1UUmhNU0F4SURBZ01DQXhJRElnTUZZeWFEVmhNU0F4SURBZ01DQXhJQzQ0TGpSc0xqazNOU0F4TGpOaExqVXVOU0F3SURBZ01TQXdJQzQyVERFMExqZ2dOUzQyWVRFZ01TQXdJREFnTVMwdU9DNDBTRGwyTVRCSU4zWXROVWd5WVRFZ01TQXdJREFnTVMwdU9DMHVORXd1TWpJMUlEa3VNMkV1TlM0MUlEQWdNQ0F4SURBdExqWk1NUzR5SURjdU5FRXhJREVnTUNBd0lERWdNaUEzYURWNmJURWdNMVk0U0RKc0xTNDNOU0F4VERJZ01UQm9ObnB0TUMwMWFEWnNMamMxTFRGTU1UUWdNMGc0ZGpKNklqNDhMM0JoZEdnK0lEd3ZaejQ4TDNOMlp6ND0ifQ==";
  }

  function name() external pure returns(string memory) {
    return "Katibeh Splitter";
  }

  function symbol() external pure returns(string memory) {
    return "split";
  }

  /**
   * @notice Creates a new minimal proxy contract and initializes it with the given split terms.
   * If the contract had already been created, its address is returned.
   * This must be called on the original implementation and not a proxy created previously.
   */
  function createSplit(Share[] memory shares) public returns (SplitterForOwners splitInstance) {
    bytes32 salt = keccak256(abi.encode(shares));
    address clone = Clones.predictDeterministicAddress(address(this), salt);
    splitInstance = SplitterForOwners(payable(clone));
    if (!clone.isContract()) {
      emit PercentSplitCreated(clone);
      Clones.cloneDeterministic(address(this), salt);
      splitInstance.initialize(shares);
    }
  }

  /**
   * @notice Returns the address for the proxy contract which would represent the given split terms.
   * @dev The contract may or may not already be deployed at the address returned.
   * Ensure that it is deployed before sending funds to this address.
   */
  function getPredictedSplitAddress(Share[] memory shares) public view returns (address) {
    bytes32 salt = keccak256(abi.encode(shares));
    return Clones.predictDeterministicAddress(address(this), salt);
  }

  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This will be called by `createSplit` after deploying the proxy so it should never be called directly.
   */
  function initialize(Share[] memory shares) public initializer {
    require(shares.length >= 2, "Split: Too few recipients");
    require(shares.length <= 7, "Split: Too many recipients");
    uint96 total;
    for (uint256 i = 0; i < shares.length; i++) {
      total += shares[i].percentInBasisPoints;
      _shares.push(shares[i]);
      emit TransferSingle(FACTORY, address(0), shares[i].recipient, 0, shares[i].percentInBasisPoints);
    }
    BASIS_POINTS = total;
  }

  /**
   * @notice Returns a tuple with the terms of this split.
   */
  function getShares() public view returns (Share[] memory) {
    return _shares;
  }

  /**
   * @notice Returns how many recipients are part of this split.
   */
  function getShareLength() public view returns (uint256) {
    return _shares.length;
  }

  /**
   * @notice Returns a recipient in this split.
   */
  function getShareRecipientByIndex(uint256 index) public view returns (address payable) {
    return _shares[index].recipient;
  }

  /**
   * @notice Returns a recipient's percent share in basis points.
   */
  function getPercentInBasisPointsByIndex(uint256 index) public view returns (uint256) {
    return _shares[index].percentInBasisPoints;
  }

  /**
   * @notice Forwards any ETH received to the recipients in this split.
   * @dev Each recipient increases the gas required to split
   * and contract recipients may significantly increase the gas required.
   */
  receive() external payable {
    _splitETH(msg.value);
  }

  /**
   * @notice Allows any ETH stored by the contract to be split among recipients.
   * @dev Normally ETH is forwarded as it comes in, but a balance in this contract
   * is possible if it was sent before the contract was created or if self destruct was used.
   */
  function splitETH() public {
    _splitETH(address(this).balance);
  }

  function _splitETH(uint256 value) internal {
    if (value > 0) {
      uint256 totalSent;
      uint256 amountToSend;
      unchecked {
        for (uint256 i = _shares.length - 1; i > 0; i--) {
          Share memory share = _shares[i];
          amountToSend = (value * share.percentInBasisPoints) / BASIS_POINTS;
          totalSent += amountToSend;
          share.recipient.sendValue(amountToSend);
          emit ETHTransferred(share.recipient, amountToSend);
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = value - totalSent;
      }
      _shares[0].recipient.sendValue(amountToSend);
      emit ETHTransferred(_shares[0].recipient, amountToSend);
    }
  }

  /**
   * @notice Anyone can call this function to split all available tokens at the provided address between the recipients.
   * @dev This contract is built to split ETH payments. The ability to attempt to split ERC20 tokens is here
   * just in case tokens were also sent so that they don't get locked forever in the contract.
   */
  function splitERC20Tokens(IERC20 erc20Contract) public {
    require(_splitERC20Tokens(erc20Contract), "Split: ERC20 split failed");
  }

  function _splitERC20Tokens(IERC20 erc20Contract) internal returns (bool) {
    try erc20Contract.balanceOf(address(this)) returns (uint256 balance) {
      if (balance == 0) {
        return false;
      }
      uint256 amountToSend;
      uint256 totalSent;
      unchecked {
        for (uint256 i = _shares.length - 1; i > 0; i--) {
          Share memory share = _shares[i];
          bool success;
          (success, amountToSend) = balance.tryMul(share.percentInBasisPoints);
          if (!success) {
            return false;
          }
          amountToSend /= BASIS_POINTS;
          totalSent += amountToSend;
          try erc20Contract.transfer(share.recipient, amountToSend) {
            emit ERC20Transferred(address(erc20Contract), share.recipient, amountToSend);
          } catch {
            return false;
          }
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = balance - totalSent;
      }
      try erc20Contract.transfer(_shares[0].recipient, amountToSend) {
        emit ERC20Transferred(address(erc20Contract), _shares[0].recipient, amountToSend);
      } catch {
        return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  /**
   * @notice Allows the split recipients to make an arbitrary contract call.
   * @dev This is provided to allow recovering from unexpected scenarios,
   * such as receiving an NFT at this address.
   *
   * It will first attempt a fair split of ERC20 tokens before proceeding.
   *
   * This contract is built to split ETH payments. The ability to attempt to make other calls is here
   * just in case other assets were also sent so that they don't get locked forever in the contract.
   */
  function proxyCall(address payable target, bytes memory callData) public onlyRecipient {
    require(!callData.startsWith(type(IERC20Approve).interfaceId), "Split: ERC20 tokens must be split");
    _splitERC20Tokens(IERC20(target));
    target.functionCall(callData);
  }
}