// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

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

    address mos = 0xcDf0b81Fea68865158fa00Bd63627d6659A1Bf69;

    function setUp() public { }

    function run() external {
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        KashDoor impl = new KashDoor();
        ERC1967Proxy proxy = new ERC1967Proxy(
                    address(impl),
                    abi.encodeWithSelector(
                        KashDoor.initialize.selector,
                        mos, address(0)
                    )
                );
        console.log("kashDoor", address(proxy));
        vm.stopBroadcast();
    }

    function update() external {
        UUPSUpgradeable proxy = UUPSUpgradeable(payable(0x4fAE90C5ec94D559abCaD7B26fbfB142D75f0fD6));
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        KashDoor impl = new KashDoor();
        proxy.upgradeTo(address(impl));
        vm.stopBroadcast();
    }

    function setPoolConfig() external {
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        KashDoor door = KashDoor(payable(0x8ADc0e2aFd67776df2F8946aA0649d8C19867C20));
        door.setPool(0x5310C07Cd8fc53bb47dDbFC8d86E1F0bcE213d17);
        door.setController(97, abi.encodePacked(0xe9EeC579739e9ff748AE827185487059a649a0FA));
        door.setController(5, abi.encodePacked(0x8F4e75EA6eE5095E4FD7385592476dabDde36099));
    }
}
