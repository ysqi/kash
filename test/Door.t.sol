// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/protocol/cross/KashDoor.sol";
import "./USDT.sol";
import "./mocks/MockPool.sol";
import "../src/utils/Utils.sol";
import "../src/protocol/KashPool.sol";
import "./base/App.sol";

contract DoorTest is Test {
    KashDoor door;
    MockERC20 ethUSDT;
    uint256 ethChainId = 5;
    App app;
    ReserveState mUSDTReserve;
    KashPool pool;

    function setUp() public {
        app = new App();
        pool = app.pool();

        mUSDTReserve = app.createReserve("mUSDT", 18);

        ethUSDT = new MockERC20("ethUSDT","ethUSDT",18);

        door = KashDoor(
            address(
                new ERC1967Proxy(
                    address(new KashDoor()),
                    abi.encodeWithSelector(
                        KashDoor.initialize.selector,
                            makeAddr("mos"), makeAddr("messenger"),
                            address(pool)
                    )
                )
            )
        );

        bytes32 sideAsset = keccak256(abi.encode(ethChainId, address(ethUSDT)));
        door.setMtoken(sideAsset, address(mUSDTReserve.asset));
        // door.setMa

        vm.prank(address(app));
        pool.setMaster(address(door));
    }

    function testCrossSuplly() public {
        address alice = makeAddr("alice");
        bytes32 sideAsset = keccak256(abi.encode(ethChainId, address(ethUSDT)));
        bytes32 suppler = Utils.toBytes32(alice);

        uint256 amount = 100e18;
        uint16 refCode = 1;
        bytes memory data = abi.encode(refCode);

        door.handleSupply(sideAsset, suppler, amount, data);

        assertEq(mUSDTReserve.asset.balanceOf(address(mUSDTReserve.creditToken)), amount);
        assertEq(mUSDTReserve.creditToken.balanceOf(alice), amount);
        
    }
}
