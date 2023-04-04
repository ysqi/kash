// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/protocol/KashPool.sol";
import "../src/libaryes/WadMath.sol";
import "./base/App.sol";

contract CounterTest is Test {
    using WadMath for uint256;

    App app;
    KashPool pool;

    function setUp() public {
        app = new App();
        pool = app.pool();

        app.changeMaster(address(this)); // support supply

        vm.label(address(pool), "kashPool");
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

    function testGetUserAccountData() external {
        ReserveState memory usdtReserve = app.createReserve("USDT", 18);
        ReserveState memory ethReserve = app.createReserve("ETH", 18);

        vm.label(address(usdtReserve.asset), "mUSDT");
        vm.label(address(usdtReserve.creditToken), "cUSDT");
        vm.label(address(usdtReserve.debitToken), "dUSDT");

        // 1 usdt= $1
        app.setOraclePrice(address(usdtReserve.asset), 1 * 1e18);
        // 1 eth = $1500
        app.setOraclePrice(address(ethReserve.asset), 1500 * 1e18);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        uint256 amount = 100 * 1e18;

        // alice supply 100u & borrow 2u
        app.supply(usdtReserve, alice, amount);
        {
            (
                uint256 totalCollateralBase,
                uint256 totalDebtBase,
                uint256 availableBorrowsBase,
                uint256 currentLiquidationThreshold,
                uint256 ltv,
                uint256 healthFactor
            ) = pool.getUserAccountData(alice);
            assertEq(availableBorrowsBase, 100 * 0.8 * 0.9 * 1e18);
        }

        vm.prank(alice);
        usdtReserve.pool.borrow(address(usdtReserve.asset), 2 * 1e18, alice);

        // bob supply 5eth+200u & borrow 200 u
        app.supply(ethReserve, bob, 5 * 1e18);
        app.supply(usdtReserve, bob, 200 * 1e18);
        vm.prank(bob);
        usdtReserve.pool.borrow(address(usdtReserve.asset), 200 * 1e18, bob);

        // check alice
        {
            (
                uint256 totalCollateralBase,
                uint256 totalDebtBase,
                uint256 availableBorrowsBase,
                uint256 currentLiquidationThreshold,
                uint256 ltv,
                uint256 healthFactor
            ) = pool.getUserAccountData(alice);

            assertEq(totalCollateralBase, 100 * 1 * 1e18, "supply100u");
            assertEq(totalDebtBase, 2 * 1e18, "borrow2u");
            assertEq(currentLiquidationThreshold, 0.9 * 1e18, "k line");
            assertEq(
                availableBorrowsBase,
                (100 * 0.8 * 0.9 - 2) * 1e18,
                "= borrowLimit - debt= 100u * 0.8 * 0.9  - 2u "
            );
            assertEq(ltv, uint256(2).wadDiv(100), "ltv=debit/supply=2/100=0.02");
            assertEq(
                uint256(healthFactor), uint256(2).wadDiv(72), "health= debit/limit=2/72=0.02777778"
            );
        }

        ReserveData memory usdtReserveData =
            usdtReserve.pool.getReserveData(address(usdtReserve.asset));

        // after 1 day
        skip(10 days);

        // borrow 2u
        {
            assertEq(
                2 * 1e18
                    + uint256(usdtReserveData.currentVariableBorrowRate).wadMul(2 * 1e18) * (10 days),
                usdtReserve.debitToken.balanceOf(alice),
                "borrow = principal plus 10days interest"
            );
        }

        {
            assertEq(
                100 * 1e18
                    + uint256(usdtReserveData.currentLiquidityRate).wadMul(100 * 1e18) * (10 days),
                usdtReserve.creditToken.balanceOf(alice),
                " cash = principal plus 10days interest"
            );
        }
    }

    function testInterestRate() external {
        ReserveState memory usdtReserve = app.createReserve("USDT", 18);

        uint256 borrows = 714533336355630733750; //714.53333636
        uint256 cash = 3419999999999999971985; // 3420

        InterestRateModel rm = InterestRateModel(usdtReserve.rateModel);

        uint256 brate = rm.borrowRate(cash, borrows, 0);
        uint256 urate = rm.utilizationRate(cash, borrows, 0);
        console.log("brate=", brate, brate * 365 days * 100 / 1e18);
        console.log("urate=", urate);

        assertEq(brate, 1254573244);
    }

    function testBorrowRate() external {
        ReserveState memory usdtReserve = app.createReserve("USDT", 18);

        vm.label(address(usdtReserve.asset), "mUSDT");
        vm.label(address(usdtReserve.creditToken), "cUSDT");
        vm.label(address(usdtReserve.debitToken), "dUSDT");

        // 1 usdt= $1
        app.setOraclePrice(address(usdtReserve.asset), 1 * 1e18);

        address alice = makeAddr("alice");
        uint256 amount = 4184.5022 * 1e18;

        app.supply(usdtReserve, alice, amount);

        skip(1 days);
        usdtReserve.pool.borrow(address(usdtReserve.asset), 714.5148 * 1e18, alice);
        // after 1 day
        skip(1 days);

        ReserveData memory usdtReserveData =
            usdtReserve.pool.getReserveData(address(usdtReserve.asset));

        console.log(usdtReserveData.currentVariableBorrowRate);
    }

    function testsetReserveInterestRateStrategyAddress() external {
        ReserveState memory usdtReserve = app.createReserve("USDT", 18);
        ReserveState memory usdcReserve = app.createReserve("USDC", 18);

        InterestRateModel newRateModel = new InterestRateModel();

        vm.prank(pool.owner());
        pool.setReserveInterestRateStrategy(address(newRateModel));

        assertEq(
            pool.getReserveData(address(usdtReserve.asset)).interestRateStrategyAddress,
            address(newRateModel),
            "should be newRateModel"
        );
        assertEq(
            pool.getReserveData(address(usdcReserve.asset)).interestRateStrategyAddress,
            address(newRateModel),
            "should be newRateModel"
        );
    }
}
