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
            uint256 ltv,
            uint256 healthFactor
        )
    {
        uint256 totalDiscounting;

        for (uint16 i = 0; i < params.reservesCount; i++) {
            if (hasSupply(params.userconfig, i) || hasBorrow(params.userconfig, i)) {
                address asset = reserveList[i];
                ReserveData storage reserve = reserveData[asset];
                (uint256 supplies, uint256 borrows) =
                    ReserveLogic.getUserBalance(reserve, params.user);

                //price
                (uint256 updateAt, uint256 wadPrice) = IOracle(params.oracle).getLastPrice(asset);
                // TODO: check update time
                // TODO: need use decimals
                totalCollateral += supplies.wadMul(wadPrice);
                totalDebt += borrows.wadMul(wadPrice);

                totalDiscounting += supplies.wadMul(wadPrice) * 8 / 10; // TODO: collateral rate=80%
            }
        }
        ltv = availableBorrows.wadDiv(totalCollateral);
        healthFactor = availableBorrows.wadDiv(totalDiscounting);
    }

    function getUserAccountDetailData(
        address asset,
        QueryUserDataParams memory params,
        mapping(address => ReserveData) storage reserveData
    ) external view returns (UserReserveData memory detail) {
        ReserveData storage reserve = reserveData[asset];
        (detail.totalSupply, detail.totalBorrows) =
            ReserveLogic.getUserBalance(reserve, params.user);

        //price
        (, detail.assetPrice) = IOracle(params.oracle).getLastPrice(asset);
        // TODO: check update time
        // TODO: need use decimals
        detail.collateralRate = 0.8 * 1e4; //80%
    }
}
