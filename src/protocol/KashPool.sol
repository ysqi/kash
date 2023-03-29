// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/IPool.sol";
import "./lib/KashSpaceStorage.sol";
import "./lib/logic/SpaceLogic.sol";
import "./lib/logic/CreditLogic.sol";
import "./lib/logic/UserLogic.sol";
import "./lib/logic/DebitLogic.sol";
import "./lib/logic/DebitLogic.sol";
import "./lib/helpers/Errors.sol";
import "./lib/KashConstants.sol";
import "./lib/upgradeable/KashUUPSUpgradeable.sol";
import "./../interfaces/IKashCrossDoor.sol";

import "@openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract KashPool is IPool, KashUUPSUpgradeable, EIP712Upgradeable, KashSpaceStorage {
    using ReserveLogic for ReserveData;

    bytes32 private constant _TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainid,address verifyingContract)"
    );

    modifier onlyMaster() {
        if (master != msg.sender) revert Errors.NO_PERMISSION();
        _;
    }

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _WITHDRAW_TYPEHASH = keccak256(
        "withdraw(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 originChainId,uint256 targetChainId,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant _BORROW_TYPEHASH = keccak256(
        "borrow(address caller,address asset,uint256 amount,bytes32 onBehalfOf,uint256 originChainId,uint256 targetChainId,uint256 nonce,uint256 deadline)"
    );

    function initialize(address oracle_) external initializer {
        if (oracle_ == address(0)) revert Errors.EMPTY_ADDRESS();

        KashUUPSUpgradeable._init();

        EIP712Upgradeable.__EIP712_init("KashPool", "v1");

        oracle = oracle_;
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
        CreditLogic.executeSupply(
            msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs, _userConfigs
        );
    }

    function verifySignature(
        bytes32 methodHash,
        address caller,
        address asset,
        uint256 amount,
        bytes32 onBehalfOf,
        uint256 originChainId,
        uint256 targetChainId,
        uint256 deadline,
        bytes memory signature
    ) public {
        if (block.timestamp > deadline) revert Errors.EXPIRED_DEADLINE();
        uint256 nonce = _useNonce[caller];
        bytes32 structHash = keccak256(
            abi.encode(
                methodHash,
                caller,
                asset,
                amount,
                onBehalfOf,
                originChainId,
                targetChainId,
                nonce,
                deadline
            )
        );
        if (
            !SignatureCheckerUpgradeable.isValidSignatureNow(
                caller, _hashTypedDataV4(originChainId, structHash), signature
            )
        ) {
            revert Errors.ILLEGAL_SIGNATURE();
        }
        unchecked {
            _useNonce[caller] = nonce + 1;
        }
    }

    function _hashTypedDataV4(uint256 targetChainId, bytes32 structHash)
        internal
        view
        returns (bytes32)
    {
        // sigh with target chain id.
        bytes32 buildDomainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), targetChainId, address(this)
            )
        );
        return ECDSAUpgradeable.toTypedDataHash(buildDomainSeparator, structHash);
    }

    function withdrawDelegate(
        address caller,
        address asset,
        uint256 amount,
        bytes32 onBehalfOf,
        uint256 originChainId,
        uint256 targetChainId,
        uint256 deadline,
        bytes memory signature
    ) external {
        verifySignature(
            _WITHDRAW_TYPEHASH,
            caller,
            asset,
            amount,
            onBehalfOf,
            originChainId,
            targetChainId,
            deadline,
            signature
        );
        CreditLogic.executeWithraw(
            caller, asset, amount, master, _reserves, _reserveConfigs, _userConfigs
        );

        IKashCrossDoor(master).handleWithdraw(caller, targetChainId, asset, onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address onBehalfOf) external {
        CreditLogic.executeWithraw(
            msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs, _userConfigs
        );
    }

    function borrow(address asset, uint256 amount, address onBehalfOf) external {
        DebitLogic.executeBorrow(
            msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs, _userConfigs
        );
    }

    function borrowDelegate(
        address caller,
        address asset,
        uint256 amount,
        bytes32 onBehalfOf,
        uint256 originChainId,
        uint256 targetChainId,
        uint256 deadline,
        bytes memory signature
    ) external {
        verifySignature(
            _BORROW_TYPEHASH,
            caller,
            asset,
            amount,
            onBehalfOf,
            originChainId,
            targetChainId,
            deadline,
            signature
        );

        DebitLogic.executeBorrow(
            caller, asset, amount, master, _reserves, _reserveConfigs, _userConfigs
        );

        IKashCrossDoor(master).handleWithdraw(caller, targetChainId, asset, onBehalfOf, amount);
    }

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
    {
        DebitLogic.executeRepay(
            msg.sender, asset, amount, onBehalfOf, _reserves, _reserveConfigs, _userConfigs
        );
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

    function getReserveRealLiquidityIndex(address asset) external view returns (uint256) {
        return _reserves[asset].getRealLiquidityIndex();
    }

    function getReserveRealBorrowIndex(address asset) external view returns (uint256) {
        return _reserves[asset].getRealBorrowIndex();
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

    function getUserReserveDetails(address user)
        external
        view
        returns (UserReserveFullData memory)
    {
        return UserLogic.getUserReserveDetails(
            QueryUserDataParams({
                user: user,
                userconfig: _userConfigs[user],
                reservesCount: _reserveCount,
                oracle: oracle
            }),
            _reserves,
            _reserveList
        );
    }

    function getUserAccountData(address user)
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
        (
            totalCollateral,
            totalDebt,
            availableBorrows,
            currentLiquidationThreshold,
            ltv,
            healthFactor
        ) = UserLogic.getUserAccountData(
            QueryUserDataParams({
                user: user,
                userconfig: _userConfigs[user],
                reservesCount: _reserveCount,
                oracle: oracle
            }),
            _reserves,
            _reserveList
        );
    }

    function getNonce(address user) external view returns (uint256) {
        return _useNonce[user];
    }

    function BRIDGE_PROTOCOL_FEE() external pure returns (uint256) {
        return 0.001 * 1e18; //
    }
}
