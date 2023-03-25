// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../KashDataTypes.sol";
import "../helpers/Errors.sol";
import "./ReserveLogic.sol";
import "./UserLogic.sol";
import "../../../interfaces/ICreditToken.sol";
import "../../../interfaces/IDebitToken.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

library DebitLogic {
    using ReserveLogic for ReserveData;
    using SafeERC20 for IERC20;

    function executeBorrow(
        address caller,
        address asset,
        uint256 assetAmount,
        address onBehalfOf,
        mapping(address => ReserveData) storage reserves,
        mapping(address => ReserveConfigurationMap) storage,
        mapping(address => UserConfigurationMap) storage userConfigs
    ) external {
        // 1. check and update reserve state
        ReserveData storage reserve = reserves[asset];
        reserve.updateState(asset);

        // TODO: revert if reserve is stopped.

        // TODO: check borrow power
        reserve.updateInterestRates(asset, 0, assetAmount);

        // 2. mint debit token

        UserLogic.switchBorrow(userConfigs[caller], reserve.id, true);

        IDebitToken(reserve.variableDebtTokenAddress).mint(
            caller, caller, assetAmount, reserve.variableBorrowIndex
        );
        // transfer
        ICreditToken creditToken = ICreditToken(reserve.creditTokenAddress);
        creditToken.transferUnderlyingTo(onBehalfOf, assetAmount);
        // 3. TODO: event
    }

    function executeRepay(
        address caller,
        address asset,
        uint256 assetAmount,
        address onBehalfOf,
        mapping(address => ReserveData) storage reserves,
        mapping(address => ReserveConfigurationMap) storage,
        mapping(address => UserConfigurationMap) storage userConfigs
    ) internal {
        // 1. check and update reserve state
        ReserveData storage reserve = reserves[asset];
        reserve.updateState(asset);
        reserve.updateInterestRates(asset, assetAmount, 0);

        // transfer asset
        ICreditToken(reserve.creditTokenAddress).handleRepayment(caller, assetAmount);
        // brun debit token
        IDebitToken(reserve.variableDebtTokenAddress).burn(
            onBehalfOf, assetAmount, reserve.variableBorrowIndex
        );
        // update borrower status
        UserLogic.switchBorrow(userConfigs[onBehalfOf], reserve.id, true);

        // 3. TODO: event
    }
}
