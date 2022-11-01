// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Comments {

    mapping(uint256 => uint256) public tokenScore;

    event Comment(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string text
    );

    function comment(
        uint256 tokenId,
        address to,
        string calldata text
    ) public {
        if(bytes(text)[0] == 0x2b) {
            tokenScore[tokenId] += 1;
        } else if (bytes(text)[0] == 0x2d) {
            tokenScore[tokenId] += 10**18;
        } else {
            tokenScore[tokenId] += 10**36;
        }

        emit Comment(tokenId, msg.sender, to, text);
    }
}