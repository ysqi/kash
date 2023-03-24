// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/protocol/KashPool.sol";
import "./base/App.sol";

contract CounterTest is Test {
    App app;
    KashPool pool;

    function setUp() public {
        app = new App();
        pool = app.pool();

        app.changeMaster(address(this)); // support supply
    }

    function testInitReserve() external {
        app.createReserve("USDT", 18);
    }

    function testSupply() external {
        ReserveState memory reserve = app.createReserve("USDT", 18);

        address alice = makeAddr("alice");
        uint256 amount = 1e20;

        //add approve
        vm.prank(alice);
        reserve.asset.approve(address(address(reserve.creditToken)), amount);

        reserve.asset.mint(alice, amount);
        reserve.pool.supply(alice, address(reserve.asset), amount, alice, 0);
        assertEq(reserve.creditToken.balanceOf(alice), 1e20);
        assertEq(reserve.asset.balanceOf(address(reserve.creditToken)), 1e20);

        //again
        address bob = makeAddr("bob");

        //add approve
        vm.prank(bob);
        reserve.asset.approve(address(address(reserve.creditToken)), amount);

        reserve.asset.mint(bob, amount);
        reserve.pool.supply(bob, address(reserve.asset), amount, bob, 0);
        assertEq(reserve.creditToken.balanceOf(bob), 1e20);
        assertEq(reserve.asset.balanceOf(address(reserve.creditToken)), 1e20 * 2);
    }

    function testWithdraw() external {
        ReserveState memory reserve = app.createReserve("USDT", 18);

        address alice = makeAddr("alice");
        uint256 amount = 1e20;

        vm.prank(alice);
        reserve.asset.approve(address(address(reserve.creditToken)), amount);
        reserve.asset.mint(alice, amount);
        reserve.pool.supply(alice, address(reserve.asset), amount, alice, 0);

        //withdraw

        address bob = makeAddr("bob");
        uint256 withdrawAmount = 1.5e18;
        reserve.pool.withdraw(alice, address(reserve.asset), withdrawAmount, bob);
        assertEq(reserve.creditToken.balanceOf(alice), amount - withdrawAmount);
        assertEq(reserve.asset.balanceOf(bob), withdrawAmount);
    }
}
