// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)
//  @authro ysqi
library WadMath {
    uint256 internal constant WAD = 1e18;

    /**
     * @notice r= x*y/1e18
     */
    function wadMul(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Store x * y in r for now.
            r := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(r, x), y))) { revert(0, 0) }

            // Scale the result down by 1e18.
            r := div(r, WAD)
        }
    }
    /**
     * @notice r= x*1e18/y
     */

    function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Store x * 1e18 in r for now.
            r := mul(x, WAD)

            // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
            if iszero(and(iszero(iszero(y)), eq(div(r, WAD), x))) { revert(0, 0) }

            // Divide r by y.
            r := div(r, y)
        }
    }
}
