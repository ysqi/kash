// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../KashDataTypes.sol";
import "../helpers/Errors.sol";
import "../../../interfaces/IDebitToken.sol";
import "../../../interfaces/ICreditToken.sol";
import "../../../interfaces/IInterestRateStrategy.sol";
import "../../../libaryes/WadMath.sol";

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@solmate/utils/SafeCastLib.sol";

library ReserveLogic {
    using SafeCastLib for uint256;
    using WadMath for uint256;

    event ReserveStateUpdated(
        address asset,
        uint256 currentVariableBorrowRate,
        uint256 currentLiquidityRate,
        uint256 variableBorrowIndex,
        uint256 liquidityIndex
    );
    event ReserveInterestRatesUpdated(
        address asset, uint256 currentVariableBorrowRate, uint256 currentLiquidityRate
    );

    function getRealLiquidityIndex(ReserveData storage reserve) internal view returns (uint256) {
        uint40 currentTime = uint40(block.timestamp);
        if (reserve.lastUpdateTimestamp >= currentTime) {
            return reserve.liquidityIndex;
        }
        uint256 rate = reserve.currentLiquidityRate * (currentTime - reserve.lastUpdateTimestamp);
        return reserve.liquidityIndex + rate.wadMul(reserve.liquidityIndex);
    }

    function getRealBorrowIndex(ReserveData storage reserve) internal view returns (uint256) {
        uint40 currentTime = uint40(block.timestamp);
        if (reserve.lastUpdateTimestamp >= currentTime) {
            return reserve.variableBorrowIndex;
        }
        uint256 rate =
            reserve.currentVariableBorrowRate * (currentTime - reserve.lastUpdateTimestamp);
        return reserve.variableBorrowIndex + rate.wadMul(reserve.liquidityIndex);
    }

    function updateState(ReserveData storage reserve, address asset) internal {
        uint40 currentTime = uint40(block.timestamp);
        // every block only update one time.
        if (reserve.lastUpdateTimestamp >= currentTime) return;

        uint256 nextBorrowIndex = getRealBorrowIndex(reserve);
        uint256 nextLiquidityIndex = getRealLiquidityIndex(reserve);

        uint256 nextTotalBorrows = IDebitToken(reserve.variableDebtTokenAddress).scaledTotalSupply()
            .wadMul(nextBorrowIndex);

        ICreditToken creditToken = ICreditToken(reserve.creditTokenAddress);

        uint256 cash = IERC20(asset).balanceOf(address(creditToken));

        uint256 nextBorrowInterestRate = IInterestRateStrategy(reserve.interestRateStrategyAddress)
            .borrowRate(cash, nextTotalBorrows, 0);
        uint256 reserveFeePoint = 0.05 * 1e18; //TODO: fixed value
        uint256 newLiquidityInterestRate = IInterestRateStrategy(
            reserve.interestRateStrategyAddress
        ).supplyRate(cash, nextTotalBorrows, 0, reserveFeePoint);

        reserve.currentVariableBorrowRate = nextBorrowInterestRate.safeCastTo128();
        reserve.liquidityIndex = nextLiquidityIndex.safeCastTo128();
        reserve.variableBorrowIndex = nextBorrowIndex.safeCastTo128();
        reserve.currentLiquidityRate = newLiquidityInterestRate.safeCastTo128();
        reserve.lastUpdateTimestamp = currentTime;

        emit ReserveStateUpdated(
            asset,
            nextBorrowInterestRate,
            newLiquidityInterestRate,
            nextBorrowInterestRate,
            nextLiquidityIndex
        );
    }

    function updateInterestRates(
        ReserveData storage reserve,
        address asset,
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) internal {
        uint256 totalBorrows = IDebitToken(reserve.variableDebtTokenAddress).totalSupply();
        ICreditToken creditToken = ICreditToken(reserve.creditTokenAddress);
        uint256 nextCash =
            IERC20(asset).balanceOf(address(creditToken)) - liquidityTaken + liquidityAdded;

        uint256 nextBorrowInterestRate = IInterestRateStrategy(reserve.interestRateStrategyAddress)
            .borrowRate(nextCash, totalBorrows, 0);
        uint256 newLiquidityInterestRate = IInterestRateStrategy(
            reserve.interestRateStrategyAddress
        ).supplyRate(nextCash, totalBorrows, 0, 0);

        reserve.currentVariableBorrowRate = nextBorrowInterestRate.safeCastTo128();
        reserve.currentLiquidityRate = nextBorrowInterestRate.safeCastTo128();

        emit ReserveInterestRatesUpdated(asset, nextBorrowInterestRate, newLiquidityInterestRate);
    }
}
