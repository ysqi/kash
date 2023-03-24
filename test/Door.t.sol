// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/cross/KashDoor.sol";
import "./USDT.sol";

contract DoorTest{
    KashDoor door;
    USDT usdt;

    function setUp() public {
        door = new KashDoor();
        usdt = new USDT();
    }

    function test() public {
        
    }
}