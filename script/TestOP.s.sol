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
    uint256 deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
    }

    function handleSupply(address who, address targetAsset, uint256 targetChainId, uint256 amount)
        external
    {
        vm.startBroadcast(deployerPrivateKey);

        KashDoor door = KashDoor(payable(0x8ADc0e2aFd67776df2F8946aA0649d8C19867C20));
        bytes32 sideAsset = keccak256(abi.encode(targetChainId, targetAsset));
        door.handleSupply(
            sideAsset, bytes32(uint256(uint160(who))), amount, abi.encode(uint16(1)), 0
        );
    }

    function addAsset(address asset, uint256 targetChainId, address targetAsset) public {
        bytes32 sideAsset = keccak256(abi.encode(targetChainId, targetAsset));
        KashDoor door = KashDoor(payable(0x8ADc0e2aFd67776df2F8946aA0649d8C19867C20));
        door.setMtoken(sideAsset, asset);
        door.setChainTokenMapping(asset, targetChainId, bytes32(uint256(uint160(targetAsset))));
    }

    function addAssetToDoor() external {
        vm.startBroadcast(deployerPrivateKey);

        // usdt
        addAsset(
            0x02096654B0f3597a6760D29370B2199E8C08e730,
            97,
            0x271Ad6b86D22535281AAe72dC9b3066636E254c0
        );
        // USDC
        addAsset(
            0x928a4804d2db43f97e9703927EfA8dd95Ca1D3ae,
            97,
            0xF339A95Ae48A8E64842B16BC7c55D5d37c1105AC
        );
        // ETH
        addAsset(
            0x27953EABe525687b10802B37CA6789026830Df6E,
            97,
            0x014F3F48b2D33D31Be556A15F15B665CfE3E6e2F
        );
        // BTC
        addAsset(
            0xFC1b80975BeADa59B69d2ec96C6bc990403A8f1A,
            97,
            0x73Dd182D43A605feEf1550Af808acfc2DfDfe883
        );

        // goeril
        // usdt
        addAsset(
            0x02096654B0f3597a6760D29370B2199E8C08e730,
            5,
            0x1A0bf00A35350b90a8bDbF220175FdC0C3c8eAcE
        );
        // USDC
        addAsset(
            0x928a4804d2db43f97e9703927EfA8dd95Ca1D3ae,
            5,
            0xE83E46471Cb6100fE7Da6b010581861b12211F8e
        );
        // ETH
        addAsset(
            0x27953EABe525687b10802B37CA6789026830Df6E,
            5,
            0x9CaE18a1FA384E3280F2fd320DC9AE1feFBb99E8
        );
        // BTC
        addAsset(
            0xFC1b80975BeADa59B69d2ec96C6bc990403A8f1A,
            5,
            0x1b9ACc886a712035c62F5261D61F00A0B23C420D
        );
    }
}
