// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/KashPool.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
/**
 *
 * How To:
 * 1. Add envrioment variable at .env file.
 * 2. run: forge script script/KashPool.s.sol:KashScript -vvvv -s "initKashPool()" --fork-url $RPC_URL
 *
 */

contract KashPoolUpdateScript is Script {
    uint256 deployerPrivateKey;

    function setUp() public { }

    function run() external {
        UUPSUpgradeable proxy = UUPSUpgradeable(payable(0x8C6Df8525528C5bd90A738AF88Ff070f4d7D4a59));

        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        KashPool impl = new KashPool();
        proxy.upgradeTo(address(impl));
        vm.stopBroadcast();
    }
}
