// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/protocol/cross/KashDoor.sol";
import "./USDT.sol";
import "./mocks/MockPool.sol";
import "../src/utils/Utils.sol";

contract DoorTest is Test {
    KashDoor door;
    USDT usdt;
    MockPool pool;

    function setUp() public {
        door = new KashDoor();
        usdt = new USDT();
        pool = new MockPool();
        door.initialize(makeAddr("mos"), makeAddr("messenger"), address(pool));

        bytes32 sideAsset = keccak256(abi.encode(5, address(usdt)));
        // door.setMtoken(sideAsset, Utils.toBytes32(address(usdt)));

        door.setPool(address(pool));
    }

    function testSuplly() public {
        address alice = makeAddr("alice");
        bytes32 sideAsset = keccak256(abi.encode(5, address(usdt)));
        bytes32 suppler = Utils.toBytes32(alice);

        uint256 amount = 100e18;
        uint16 refCode = 1;
        bytes memory data = abi.encode(refCode);
        door.handleSupply(sideAsset, suppler, amount, data);
    }
}
