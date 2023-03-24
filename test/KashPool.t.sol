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
        vm.prank(alice);
        reserve.pool.supply(address(reserve.asset), amount, alice, 0);
        assertEq(reserve.creditToken.balanceOf(alice), 1e20);
        assertEq(reserve.asset.balanceOf(address(reserve.creditToken)), 1e20);

        //again
        address bob = makeAddr("bob");

        //add approve
        vm.prank(bob);
        reserve.asset.approve(address(address(reserve.creditToken)), amount);

        reserve.asset.mint(bob, amount);
        vm.prank(bob);
        reserve.pool.supply(address(reserve.asset), amount, bob, 0);
        assertEq(reserve.creditToken.balanceOf(bob), 1e20);
        assertEq(reserve.asset.balanceOf(address(reserve.creditToken)), 1e20 * 2);
    }

    function testWithdraw() external {
        ReserveState memory reserve = app.createReserve("USDT", 18);

        address alice = makeAddr("alice");
        uint256 amount = 1e20;

        app.supply(reserve, alice, amount);

        //withdraw

        address bob = makeAddr("bob");
        uint256 withdrawAmount = 1.5e18;
        vm.prank(alice);
        reserve.pool.withdraw(address(reserve.asset), withdrawAmount, bob);
        assertEq(reserve.creditToken.balanceOf(alice), amount - withdrawAmount);
        assertEq(reserve.asset.balanceOf(bob), withdrawAmount);
    }

    function testBorrow() external {
        ReserveState memory usdtReserve = app.createReserve("USDT", 18);
        ReserveState memory ethReserve = app.createReserve("ETH", 18);
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        uint256 amount = 1e20;

        app.supply(usdtReserve, alice, amount);
        app.supply(ethReserve, bob, 1e30);

        // borrow eth

        uint256 borrowAmount = 1e18;
        vm.prank(alice);
        ethReserve.pool.borrow(address(ethReserve.asset), borrowAmount, alice);
        assertEq(ethReserve.asset.balanceOf(alice), borrowAmount);
        assertEq(ethReserve.debitToken.balanceOf(alice), borrowAmount);

        skip(10 minutes);

        //repay
        vm.startPrank(alice);
        ethReserve.asset.approve(address(ethReserve.creditToken), borrowAmount);
        ethReserve.pool.repay(address(ethReserve.asset), borrowAmount, 0, alice);
        vm.stopPrank();

        // The rest is interest
        uint256 debits = ethReserve.debitToken.balanceOf(alice);
        assertGe(debits, 0);
        assertLt(debits, 1e18 / 2);

        // bob get more eth
    }
}
