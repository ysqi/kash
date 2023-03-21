// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../KashDataTypes.sol";
import "../helpers/Errors.sol";
import "@openzeppelin/utils/Address.sol";

library SpaceLogic {
    using Address for address;

    function executeRemoveReserve(
        mapping(address => ReserveData) storage reserveData,
        mapping(uint16 => address) storage reserveList,
        address asset
    ) external {
        if (reserveData[asset].kTokenAddress == address(0)) revert Errors.RESERVE_NOT_FOUND();

        uint16 id = reserveData[asset].id;
        reserveList[id] = address(0);
        reserveData[asset].id = 0;
        reserveData[asset].kTokenAddress = address(0);
    }

    function executeInitReserve(
        mapping(address => ReserveData) storage reserveData,
        mapping(uint16 => address) storage reserveList,
        InitReserveParams memory params
    ) external returns (bool) {
        if (!params.asset.isContract()) revert Errors.NOT_CONTRACT();
        if (!params.kTokenAddress.isContract()) revert Errors.NOT_CONTRACT();
        // TODO: only support vaiable debt.
        // if (!params.stableDebtTokenAddress.isContract()) revert Errors.NOT_CONTRACT();
        if (!params.variableDebtTokenAddress.isContract()) revert Errors.NOT_CONTRACT();
        if (!params.interestRateStrategyAddress.isContract()) revert Errors.NOT_CONTRACT();

        ReserveData storage reserve = reserveData[params.asset];
        if (reserve.kTokenAddress != address(0)) revert Errors.ASSET_EXIST_RESERVE();

        reserve.kTokenAddress = params.kTokenAddress;
        reserve.stableDebtTokenAddress = params.stableDebtTokenAddress;
        reserve.variableDebtTokenAddress = params.variableDebtTokenAddress;
        reserve.interestRateStrategyAddress = params.interestRateStrategyAddress;

        //find id
        for (uint16 i = 0; i < params.reservesCount; i++) {
            if (reserveList[i] == address(0)) {
                reserveData[params.asset].id = i;
                reserveList[i] = params.asset;
                return false;
            }
        }

        //else append
        //TODO: check cap
        reserveList[params.reservesCount] = params.asset;
        reserveData[params.asset].id = params.reservesCount;
        return true;
    }
}
