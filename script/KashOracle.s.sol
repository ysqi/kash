// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/lib/KashOracle.sol";
/**
 *
 * How To:
 * 1. Add envrioment variable at .env file.
 * 2. run: forge script script/KashPool.s.sol:KashScript -vvvv -s "initKashPool()" --fork-url $RPC_URL
 *
 */

contract KashOracleScript is Script {
    uint256 deployerPrivateKey;

    function setUp() public { }

    function setAssetPrice() external {
        address[] memory list = new address[](4);
        uint256[] memory prices = new uint256[](4);

        // USDT
        list[0] = 0xA0a121C77a3317Cf31B14b5a3089C2DAc70b5c3B; //USDT
        prices[0] = 1 * 1e18;

        list[1] = 0xFF8A1A10cFa544e9F1A77E121D4F393293A7Fa3E; //USDC
        prices[1] = 1 * 1e18;

        list[2] = 0xaBB9ADE0BC8C132d4F75c15538370E66A0734518; // ETH
        prices[2] = 1700 * 1e18;

        list[3] = 0xc44D60Da3ed467227C81BFAAC31b882880Cc13e8; // BTC
        prices[3] = 27000 * 1e18;

        KashOracle oracle = KashOracle(0xDdb2395921228Af6f49837a4acdc758E49065214);

        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        oracle.batchSetPrice(list, prices);
        vm.stopBroadcast();
    }
}
