// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/cross/KashDoor.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

/**
 *
 * How To:
 * 1. Add envrioment variable at .env file.
 * 2. run: forge script script/KashPool.s.sol:KashScript -vvvv -s "initKashPool()" --fork-url $RPC_URL
 *
 */

contract TestOPScript is Script {
    function setUp() public {
        uint256 deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
    }

    function handleSupply(address who, address targetAsset, uint256 targetChainId, uint256 amount)
        external
    {
        KashDoor door = KashDoor(payable(0x4fAE90C5ec94D559abCaD7B26fbfB142D75f0fD6));
        bytes32 sideAsset = keccak256(abi.encode(targetChainId, targetAsset));
        door.handleSupply(sideAsset, bytes32(uint256(uint160(who))), amount, abi.encode(uint16(1)));
    }

    function addAsset(address asset, uint256 targetChainId, address targetAsset) public {
        bytes32 sideAsset = keccak256(abi.encode(targetChainId, targetAsset));
        KashDoor door = KashDoor(payable(0x4fAE90C5ec94D559abCaD7B26fbfB142D75f0fD6));
        door.setMtoken(sideAsset, asset);
        door.setChainTokenMapping(asset, targetChainId, bytes32(uint256(uint160(targetAsset))));
    }

    function addAssetToDoor() external {
        // usdt
        addAsset(
            0xA0a121C77a3317Cf31B14b5a3089C2DAc70b5c3B,
            97,
            0x271Ad6b86D22535281AAe72dC9b3066636E254c0
        );
        // USDC
        addAsset(
            0xFF8A1A10cFa544e9F1A77E121D4F393293A7Fa3E,
            97,
            0xF339A95Ae48A8E64842B16BC7c55D5d37c1105AC
        );
        // ETH
        addAsset(
            0xaBB9ADE0BC8C132d4F75c15538370E66A0734518,
            97,
            0x014F3F48b2D33D31Be556A15F15B665CfE3E6e2F
        );
        // BTC
        addAsset(
            0xc44D60Da3ed467227C81BFAAC31b882880Cc13e8,
            97,
            0x73Dd182D43A605feEf1550Af808acfc2DfDfe883
        );

        // goeril
        // usdt
        addAsset(
            0xA0a121C77a3317Cf31B14b5a3089C2DAc70b5c3B,
            5,
            0x1A0bf00A35350b90a8bDbF220175FdC0C3c8eAcE
        );
        // USDC
        addAsset(
            0xFF8A1A10cFa544e9F1A77E121D4F393293A7Fa3E,
            5,
            0xE83E46471Cb6100fE7Da6b010581861b12211F8e
        );
        // ETH
        addAsset(
            0xaBB9ADE0BC8C132d4F75c15538370E66A0734518,
            5,
            0x9CaE18a1FA384E3280F2fd320DC9AE1feFBb99E8
        );
        // BTC
        addAsset(
            0xc44D60Da3ed467227C81BFAAC31b882880Cc13e8,
            5,
            0x1b9ACc886a712035c62F5261D61F00A0B23C420D
        );
    }
}
