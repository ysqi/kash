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

    function updateState(ReserveData storage reserve, address asset) internal {
        uint40 currentTime = uint40(block.timestamp);
        // every block only update one time.
        if (reserve.lastUpdateTimestamp >= currentTime) {
            return;
        }
        uint256 rate =
            reserve.currentVariableBorrowRate * (currentTime - reserve.lastUpdateTimestamp);

        if (reserve.variableBorrowIndex == 0) {
            reserve.variableBorrowIndex = WadMath.WAD.safeCastTo128();
        }

        uint256 newBorrowIndex =
            reserve.variableBorrowIndex + rate * reserve.variableBorrowIndex / WadMath.WAD;
        if (newBorrowIndex == 0) {
            newBorrowIndex = WadMath.WAD;
        }

        //  totalBorrows =  index *  scaledTotalSupply
        uint256 totalBorrows = reserve.variableBorrowIndex
            * IDebitToken(reserve.variableDebtTokenAddress).scaledTotalSupply() / WadMath.WAD;

        //  totalSupply =  index * scaledTotalSupply
        ICreditToken ktoken = ICreditToken(reserve.creditTokenAddress);
        uint256 cash = IERC20(asset).balanceOf(address(ktoken));
        uint256 scaledCash = ktoken.scaledTotalSupply();
        uint256 currentLiquidityRate =
            scaledCash == 0 ? WadMath.WAD : (cash + totalBorrows).wadDiv(scaledCash);

        uint256 newLiquidityIndex =
            reserve.liquidityIndex + reserve.liquidityIndex * currentLiquidityRate / WadMath.WAD;
        if (newLiquidityIndex == 0) {
            newLiquidityIndex = WadMath.WAD;
        }

        uint256 newInterestRates = IInterestRateStrategy(reserve.interestRateStrategyAddress)
            .borrowRate(IERC20(asset).balanceOf(reserve.creditTokenAddress), totalBorrows, 0);

        reserve.currentVariableBorrowRate = newInterestRates.safeCastTo128();
        reserve.liquidityIndex = newLiquidityIndex.safeCastTo128();
        reserve.variableBorrowIndex = newBorrowIndex.safeCastTo128();
        reserve.currentLiquidityRate = currentLiquidityRate.safeCastTo128();
        reserve.lastUpdateTimestamp = currentTime;

        emit ReserveStateUpdated(
            asset, newInterestRates, currentLiquidityRate, newBorrowIndex, newLiquidityIndex
        );
    }

    function updateInterestRates(
        ReserveData storage reserve,
        address asset,
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) internal {
        //  totalBorrows =  index *  scaledTotalSupply
        uint256 totalBorrows = reserve.variableBorrowIndex
            * IDebitToken(reserve.variableDebtTokenAddress).scaledTotalSupply() / WadMath.WAD;

        //  totalSupply =  index * scaledTotalSupply
        ICreditToken ktoken = ICreditToken(reserve.creditTokenAddress);
        uint256 cash = IERC20(asset).balanceOf(address(ktoken));
        uint256 currentLiquidityRate =
            (cash + totalBorrows - liquidityTaken + liquidityAdded) / ktoken.scaledTotalSupply();

        uint256 newLiquidityIndex =
            reserve.liquidityIndex + reserve.liquidityIndex * currentLiquidityRate;

        uint256 newInterestRates = IInterestRateStrategy(reserve.interestRateStrategyAddress)
            .borrowRate(cash - liquidityTaken + liquidityAdded, totalBorrows, 0);

        reserve.currentVariableBorrowRate = newInterestRates.safeCastTo128();

        reserve.liquidityIndex = newLiquidityIndex.safeCastTo128();
        reserve.currentLiquidityRate = currentLiquidityRate.safeCastTo128();
    }
}
