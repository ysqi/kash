// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/protocol/cross/KashDoor.sol";
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
            payable(
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
                        keccak256(bytes("KashPool")),
                        keccak256(bytes("v1")),
                        212,
                        verifycontract
                    )
                ),
                keccak256(
                    abi.encode(
                        keccak256(
                            "withdraw(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 chainId,uint256 deadline,bytes signature)"
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

    bytes32 private constant _WITHDRAW_TYPEHASH = keccak256(
        "withdraw(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 originChainId,uint256 targetChainId,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant _BORROW_TYPEHASH = keccak256(
        "borrow(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 originChainId,uint256 targetChainId,uint256 nonce,uint256 deadline)"
    );

    function testSign() public {
        address caller = 0x6Ecb1e890b68DFa299DdD4856cf30a3d38867B47;
        address asset = 0x0d18c17aef629f4ea57C6D1372695a7641204925;
        uint256 amount = 1000000000000000000000;
        bytes32 onBehalfOf = 0x00000000000000000000000055876b3f4c456a203836f33387d110dea0beff73;
        uint256 chainId = 5;
        uint256 nonce = 0;
        uint256 deadline = 1779739860;
        console2.log(block.chainid);
        console2.log(address(pool));

        bytes memory sign =
            hex"3eada6a4795b4ec691a2ea8df0aba34871e6bf5af497a6892d0611831a9fb7c767ef49423b0ee4f993daf195a21b6184ceda188ac1d0e3ec91459fbf602297111b";
        pool.verifySignature(
            _WITHDRAW_TYPEHASH, caller, asset, amount, onBehalfOf, chainId, chainId, deadline, sign
        );
    }

    function testSideAssetHash() external {
        address targetToken = 0x0d18c17aef629f4ea57C6D1372695a7641204925;
        uint256 chainId = 5;

        console2.logBytes(abi.encode(chainId, targetToken));
        bytes32 sideAsset1 = keccak256(abi.encode(chainId, targetToken));
        bytes32 sideAsset2 = keccak256(abi.encode(chainId, bytes32(uint256(uint160(targetToken)))));

        assertEq(sideAsset1, sideAsset2);
    }
}
