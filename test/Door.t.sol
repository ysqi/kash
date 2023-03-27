// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/protocol/cross/KashDoor.sol";
import "./USDT.sol";
import "./mocks/MockPool.sol";
import "../src/utils/Utils.sol";
import "../src/protocol/KashPool.sol";
import "./base/App.sol";

import "./Sign.sol";

contract DoorTest is Test, Sign {
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

    function testCrossBorrow() public {
        testCrossSuplly();
        address asset = address(ethUSDT);
        uint256 amount = 100e18;
        (address alice, uint256 key) = makeAddrAndKey("alice");
        // vm.prank(alice);
        bytes memory sign = makeWithdrawCallData(
            key,
            makeAddr("verifyContract"),
            makeAddr("call"),
            makeAddr("asset"),
            100e18,
            Utils.toBytes32(makeAddr("onBehalfOf")),
            ethChainId,
            9999,
            1
        );
    }

    function makeWithdrawCallData(
        uint256 privateKey,
        address verifyContract,
        address caller,
        address asset,
        uint256 amount,
        bytes32 onBehalfOf,
        uint256 chainId,
        uint256 deadline,
        uint256 nonce
    ) public returns (bytes memory) {
        address owner = vm.addr(privateKey);
        bytes32 hash = makeWithdrawHash(
            verifyContract, caller, asset, amount, onBehalfOf, chainId, deadline, nonce
        );
        uint256 key = privateKey;
        vm.startPrank(owner);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);

        return abi.encode(v, r, s);
    }

    function makeWithdrawHash(
        address verifycontract,
        address caller,
        address asset,
        uint256 amount,
        bytes32 onBehalfOf,
        uint256 chainId,
        uint256 deadline,
        uint256 nonce
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                keccak256(
                    abi.encode(
                        keccak256(
                            "EIP712Domain(string name,string version,uint256 chainid,address verifyingContract)"
                        ),
                        keccak256(bytes("Kash DAPP")),
                        keccak256(bytes("1")),
                        212,
                        verifycontract
                    )
                ),
                keccak256(
                    abi.encode(
                        keccak256(
                            "withdrawDelegate(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 chainId,uint256 deadline,bytes signature)"
                        ),
                        caller,
                        asset,
                        amount,
                        onBehalfOf,
                        nonce,
                        deadline
                    )
                )
            )
        );
    }
}
