// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

library Utils {
    function fromBytes(bytes memory bys) internal pure returns (address addr){
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function toBytes(address self) internal pure returns (bytes memory b) {
        b = abi.encodePacked(self);
    }
}