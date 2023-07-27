// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18, sd, pow } from "@prb/math/src/SD59x18.sol";
// import { UD60x18, ud, pow } from "@prb/math/src/UD60x18.sol";

contract expTest {
    // function power(UD60x18 x, UD60x18 y) public pure returns (UD60x18 result){
    //     return pow(x,y);
    // }
    function powerInt(SD59x18 x, SD59x18 y) public pure returns (SD59x18 result){
        return pow(x,y);
    }
}