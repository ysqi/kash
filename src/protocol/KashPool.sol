// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./lib/KashSpaceStorage.sol";
import "./lib/logic/SpaceLogic.sol";
import "./lib/KashConstants.sol";
import "./lib/upgradeable/KashUUPSUpgradeable.sol";

contract KashPool is KashUUPSUpgradeable, KashSpaceStorage {
    function initialize() external initializer {
        KashUUPSUpgradeable._init();
    }

    function initReserve(
        address asset,
        address kTokenAddr,
        address interestRateStrategyAddr,
        address variableDebtToken
    ) external onlyOwner {
        if (
            SpaceLogic.executeInitReserve(
                _reserves,
                _reserveList,
                InitReserveParams({
                    asset: asset,
                    kTokenAddress: kTokenAddr,
                    stableDebtTokenAddress: address(0),
                    variableDebtTokenAddress: variableDebtToken,
                    interestRateStrategyAddress: interestRateStrategyAddr,
                    reservesCount: _reserveCount,
                    maxNumberReserves: MAX_NUMBER_RESERVES
                })
            )
        ) _reserveCount++;
    }

    function dropReserve(address asset) external onlyOwner {
        SpaceLogic.executeRemoveReserve(_reserves, _reserveList, asset);
        _reserveCount--;
    }
}
