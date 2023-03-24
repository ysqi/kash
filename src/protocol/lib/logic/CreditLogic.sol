// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../KashDataTypes.sol";
import "../helpers/Errors.sol";
import "./ReserveLogic.sol";
import "../../../interfaces/ICreditToken.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

library CreditLogic {
    using ReserveLogic for ReserveData;
    using SafeERC20 for IERC20;

    function executeSupply(
        address caller,
        address asset,
        uint256 assetAmount,
        address onBehalfOf,
        mapping(address => ReserveData) storage reserves,
        mapping(address => ReserveConfigurationMap) storage
    ) external {
        // 1. check and update reserve state
        ReserveData storage reserve = reserves[asset];
        reserve.updateState(asset);

        // TODO: revert if reserve is stopped.

        // 2. mint kToken
        ICreditToken ktoken = ICreditToken(reserve.creditTokenAddress);
        ktoken.mint(caller, onBehalfOf, assetAmount, reserve.liquidityIndex);
        // 3. TODO: event
    }

    function executeWithraw(
        address caller,
        address asset,
        uint256 assetAmount,
        address onBehalfOf,
        mapping(address => ReserveData) storage reserves,
        mapping(address => ReserveConfigurationMap) storage
    ) internal {
        // 1. check and update reserve state
        ReserveData storage reserve = reserves[asset];
        reserve.updateState(asset);

        // TODO: validateWithdraw
        uint256 index = reserve.liquidityIndex;

        reserve.updateInterestRates(asset, 0, assetAmount);

        ICreditToken(reserve.creditTokenAddress).burn(
            caller, onBehalfOf, assetAmount, reserve.liquidityIndex
        );
        // 3. TODO: event
    }
}
