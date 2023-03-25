// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../KashDataTypes.sol";
import "../helpers/Errors.sol";
import "../../../interfaces/ICreditToken.sol";
import "../../../interfaces/IOracle.sol";
import "../../../libaryes/WadMath.sol";

import "./ReserveLogic.sol";

import "@openzeppelin/utils/Address.sol";

library UserLogic {
    using WadMath for uint256;

    function _switchState(UserConfigurationMap storage cfg, uint16 index, bool state) private {
        uint256 data = cfg.data;
        if (state) {
            // Set the bit at the rid to 1.
            data |= (1 << index);
        } else {
            // Set the bit at the rid to 0.
            data &= ~(1 << index);
        }
        cfg.data = data;
    }

    function switchSupply(UserConfigurationMap storage cfg, uint16 rid, bool state) internal {
        _switchState(cfg, rid * 2, state);
    }

    function switchBorrow(UserConfigurationMap storage cfg, uint16 rid, bool state) internal {
        _switchState(cfg, rid * 2 + 1, state);
    }

    function hasSupply(UserConfigurationMap memory cfg, uint16 rid) internal pure returns (bool) {
        return (cfg.data & (1 << (rid * 2))) != 0;
    }

    function hasBorrow(UserConfigurationMap memory cfg, uint16 rid) internal pure returns (bool) {
        return (cfg.data & (1 << (rid * 2 + 1))) != 0;
    }

    function getUserAccountData(
        QueryUserDataParams memory params,
        mapping(address => ReserveData) storage reserveData,
        mapping(uint16 => address) storage reserveList
    )
        external
        view
        returns (
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 availableBorrows,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        uint256 totalDiscounting;

        for (uint16 i = 0; i < params.reservesCount; i++) {
            if (hasSupply(params.userconfig, i) || hasBorrow(params.userconfig, i)) {
                address asset = reserveList[i];

                UserReserveData memory detail = getUserAccountDetailData(asset, params, reserveData);

                totalCollateral += detail.totalSupply.wadMul(detail.assetPrice);
                totalDebt += detail.totalBorrows.wadMul(detail.assetPrice);
                totalDiscounting +=
                    detail.totalSupply.wadMul(detail.assetPrice).wadMul(detail.collateralRate);
            }
        }

        currentLiquidationThreshold = 0.8 * 1e18; // fixed value 80%
        uint256 borrowLimit = totalDiscounting.wadMul(currentLiquidationThreshold);

        ltv = totalDebt.wadDiv(totalCollateral);
        healthFactor = totalDebt.wadDiv(totalDiscounting);
        availableBorrows = borrowLimit > totalDebt ? borrowLimit - totalDebt : 0;

        return (
            totalCollateral,
            totalDebt,
            availableBorrows,
            currentLiquidationThreshold,
            ltv,
            healthFactor
        );
    }

    function getUserAccountDetailData(
        address asset,
        QueryUserDataParams memory params,
        mapping(address => ReserveData) storage reserveData
    ) internal view returns (UserReserveData memory detail) {
        ReserveData storage reserve = reserveData[asset];
        (detail.totalSupply, detail.totalBorrows) =
            ReserveLogic.getUserBalance(reserve, params.user);

        //price
        (, detail.assetPrice) = IOracle(params.oracle).getLastPrice(asset);
        // TODO: check update time
        // TODO: need use decimals
        // TODO: collateral rate=80%
        detail.collateralRate = 0.8 * 1e18; //80%
    }
}
