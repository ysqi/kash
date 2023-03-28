// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/cross/KashDoor.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
/**
 *
 * How To:
 * 1. Add envrioment variable at .env file.
 * 2. run: forge script script/KashPool.s.sol:KashScript -vvvv -s "initKashPool()" --fork-url $RPC_URL
 *
 */

contract KashDoorScript is Script {
    uint256 deployerPrivateKey;

    function setUp() public { }

    function update() external {
        UUPSUpgradeable proxy = UUPSUpgradeable(payable(0x8C6Df8525528C5bd90A738AF88Ff070f4d7D4a59));
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        KashDoor impl = new KashDoor();
        proxy.upgradeTo(address(impl));
        KashDoor(payable(address(proxy))).transferOwnership(
            0x1A0bf00A35350b90a8bDbF220175FdC0C3c8eAcE
        );
        vm.stopBroadcast();
    }
}
