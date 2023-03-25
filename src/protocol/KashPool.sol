// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/IPool.sol";
import "./lib/KashSpaceStorage.sol";
import "./lib/logic/SpaceLogic.sol";
import "./lib/logic/CreditLogic.sol";
import "./lib/logic/DebitLogic.sol";
import "./lib/helpers/Errors.sol";
import "./lib/KashConstants.sol";
import "./lib/upgradeable/KashUUPSUpgradeable.sol";
import "./../interfaces/IKashCrossDoor.sol";

import "@openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract KashPool is IPool, KashUUPSUpgradeable, EIP712Upgradeable, KashSpaceStorage {
    modifier onlyMaster() {
        if (master != msg.sender) revert Errors.NO_PERMISSION();
        _;
    }

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _WITHDRAW_TYPEHASH = keccak256(
        "withdraw(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 chainId,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant _BORROW_TYPEHASH = keccak256(
        "borrow(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 chainId,uint256 nonce,uint256 deadline)"
    );

    function initialize() external initializer {
        KashUUPSUpgradeable._init();

        EIP712Upgradeable.__EIP712_init("KashPool", "v1");
    }

    function setMaster(address addr) external onlyOwner {
        master = addr; // TODO: event
    }

    function initReserve(
        address asset,
        address creditTokenAddress,
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
                    creditTokenAddress: creditTokenAddress,
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

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        external
    {
        CreditLogic.executeSupply(msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs);
    }

    function withdrawDelegate(
        address caller,
        address asset,
        uint256 amount,
        bytes32 onBehalfOf,
        uint256 chainId,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256) {
        if (block.timestamp > deadline) revert Errors.EXPIRED_DEADLINE();

        bytes32 structHash = keccak256(
            abi.encode(
                _WITHDRAW_TYPEHASH,
                caller,
                asset,
                amount,
                onBehalfOf,
                chainId,
                _useNonce[caller],
                deadline
            )
        );
        if (
            !SignatureCheckerUpgradeable.isValidSignatureNow(
                caller, _hashTypedDataV4(structHash), signature
            )
        ) {
            revert Errors.ILLEGAL_SIGNATURE();
        }
        _useNonce[caller]++;
        CreditLogic.executeWithraw(caller, asset, amount, master, _reserves, _reserveConfigs);

        IKashCrossDoor(master).handleWithdraw(caller, chainId, asset, onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address onBehalfOf)
        external
        returns (uint256)
    {
        CreditLogic.executeWithraw(
            msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs
        );
    }

    function borrow(address asset, uint256 amount, address onBehalfOf) external {
        DebitLogic.executeBorrow(msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs);
    }

    function borrowDelegate(
        address caller,
        address asset,
        uint256 amount,
        bytes32 onBehalfOf,
        uint256 chainId,
        uint256 deadline,
        bytes memory signature
    ) external {
        if (block.timestamp > deadline) revert Errors.EXPIRED_DEADLINE();

        bytes32 structHash = keccak256(
            abi.encode(
                _BORROW_TYPEHASH,
                caller,
                asset,
                amount,
                onBehalfOf,
                chainId,
                _useNonce[caller],
                deadline
            )
        );

        if (
            !SignatureCheckerUpgradeable.isValidSignatureNow(
                caller, _hashTypedDataV4(structHash), signature
            )
        ) {
            revert Errors.ILLEGAL_SIGNATURE();
        }
        _useNonce[caller]++;

        DebitLogic.executeBorrow(caller, asset, amount, master, _reserves, _reserveConfigs);

        IKashCrossDoor(master).handleWithdraw(caller, chainId, asset, onBehalfOf, amount);
    }

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256)
    {
        DebitLogic.executeRepay(msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs);
    }

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
