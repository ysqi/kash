// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/IPool.sol";
import "./lib/KashSpaceStorage.sol";
import "./lib/logic/SpaceLogic.sol";
import "./lib/logic/CreditLogic.sol";
import "./lib/helpers/Errors.sol";
import "./lib/KashConstants.sol";
import "./lib/upgradeable/KashUUPSUpgradeable.sol";

contract KashPool is IPool, KashUUPSUpgradeable, KashSpaceStorage {
    modifier onlyMaster() {
        if (master != msg.sender) revert Errors.NO_PERMISSION();
        _;
    }

    function initialize() external initializer {
        KashUUPSUpgradeable._init();
    }

    function setMaster(address addr) external onlyOwner {
        master = addr; // TODO: event
    }

    function initReserve(
        address asset,
        address kTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external onlyOwner {
        if (
            SpaceLogic.executeInitReserve(
                _reserves,
                _reserveList,
                InitReserveParams({
                    asset: asset,
                    kTokenAddress: kTokenAddress,
                    stableDebtTokenAddress: stableDebtAddress,
                    variableDebtTokenAddress: variableDebtAddress,
                    interestRateStrategyAddress: interestRateStrategyAddress,
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

    function supply(
        address caller,
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external onlyMaster {
        CreditLogic.executeSupply(caller, asset, amount, onBehalfOf, _reserves, _reserveConfigs);
    }

    function withdraw(address caller, address asset, uint256 amount, address onBehalfOf)
        external
        onlyMaster
        returns (uint256)
    {
        CreditLogic.executeWithraw(caller, asset, amount, onBehalfOf, _reserves, _reserveConfigs);
    }

    function borrow(
        address caller,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external { }

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256)
    { }

    function setConfiguration(address asset, ReserveConfigurationMap calldata configuration)
        external
        onlyOwner
    {
        SpaceLogic.executeSetConfiguration(asset, _reserveConfigs, configuration);
    }

    function getConfiguration(address asset)
        external
        view
        returns (ReserveConfigurationMap memory)
    {
        return _reserveConfigs[asset];
    }

    function getUserConfiguration(address user)
        external
        view
        returns (UserConfigurationMap memory)
    {
        return _userConfigs[user];
    }

    function getReserveData(address asset) external view returns (ReserveData memory) {
        return _reserves[asset];
    }

    function getReservesList() external view returns (address[] memory) {
        uint16 count = _reserveCount;
        address[] memory list = new address[](count);
        for (uint16 i = 0; i < count; i++) {
            list[i] = _reserveList[i];
        }
        return list;
    }

    function getReserveAddressById(uint16 id) external view returns (address) {
        return _reserveList[id];
    }

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    { }

    function BRIDGE_PROTOCOL_FEE() external pure returns (uint256) {
        return 0.001 * 1e18; //
    }
}
