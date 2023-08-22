// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../storage/DataStorage.sol";

// game developer depoloys contract
contract FeeUtils is DataStorage {

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;
    
    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;
    
    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;
    
    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMathCommon.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two queations:
    ///     1) x * y = type(uint256).max * SCALE
    ///     2) (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    
        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }
    
        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }
    
        require(SCALE > prod1);
    
        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }
    
    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;
    
        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = mulDivFixedPoint(x, x);
    
            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = mulDivFixedPoint(result, x);
            }
        }
    }
    
    function publicFee(uint256 x) internal pure returns (uint256 result){
        uint256 levev = findLevel(x);
        if(levev == 1){
            return pow(10**18+10**17,x);
        }else{
            return pow(10**18+10**17/levev,x)+(levev)*10**18;
        }
    }
    
    //@param x The base as an unsigned total supply
    //@param A The base as an unsigned 60.18-decimal fixed-point number.
    //@param B The base as an signed 59.18-decimal fixed-point number.
    //@param C The base as an signed 59.18-decimal fixed-point number.
    //@param D The base as an signed 59.18-decimal fixed-point number.
    function privateFee(uint256 x, Pricing memory pricing) internal pure returns (uint256 result){
        require(
            x < pricing.totalSupply,
            "Factory1155: Maximum supply reached."
        );
        //return B*pow(A,x)/10*18+C*x/10**18+D/10**18
        //int res = C*int(x)+int(D);
        int res = pricing.B*int(pow(pricing.A,x))/10**18+pricing.C*int(x)+pricing.D;
        if (res<0){
            return 0;
        }else{
            return uint256(res);
        }
    }
    
    function findLevel(uint256 x) internal pure returns (uint256 result){
        if(x<26){
            //1
            return 1;
        }else if (x<454){
            //2
            return 10;
        }
        else if (x<6808){
            //3
            return 100;
        }
        else if (x<91058){
            //4
            return 1000;
        }
        else if (x<1140765){
            //5
            return 10000;
        }
        else if (x<13710000){
            //6
            return 100000;
        }
        else if (x<160130000){
            //7
            return 1000000;
        }
        else if (x<1831500000){
            //8
            return 10000000;
        }
        else if (x<20618000000){
            //9
            return 100000000;
        }
        else if (x<229200000000){
            //10
            return 1000000000;
        }
        else if (x<2522300000000){
            //11
            return 10000000000;
        }
        else{
            //12
            return 100000000000;
        }
    }
    
    
    
    function findDigit(uint256 x) internal pure returns (uint256 result){
        if(x<10){
            return 0;
        }else if (x<100){
            return 1;
        }
        else if (x<1000){
            return 2;
        }
        else if (x<10000){
            return 3;
        }
        else if (x<100000){
            return 4;
        }
        else if (x<1000000){
            return 5;
        }
        else if (x<10000000){
            return 6;
        }
        else if (x<100000000){
            return 7;
        }
        else if (x<1000000000){
            return 8;
        }
        else if (x<10000000000){
            return 9;
        }
    }
}