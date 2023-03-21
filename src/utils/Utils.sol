// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

library Utils {
    function fromBytes(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function toBytes(address self) internal pure returns (bytes memory b) {
        b = abi.encodePacked(self);
    }

    function toBytes32(address self) internal pure returns (bytes32 b) {
        b = bytes32(uint256(uint160(self)));
    }

    function fromBytes32(bytes32 bys32) internal pure returns (address b) {
        b = address(uint160(uint256(bys32)));
    }
}
