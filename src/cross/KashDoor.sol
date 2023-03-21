// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../protocol/lib/upgradeable/KashUUPSUpgradeable.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IKashCrossDoor.sol";
import "../utils/Utils.sol";
import "../interfaces/IMOSV3.sol";
import "../Error.sol";

contract KashDoor is KashUUPSUpgradeable, IKashCrossDoor {
    IPool pool;
    IMOSV3 mos;
    address messenger;
    address controller;
    uint256 controllerChainid;
    uint256 gasLimit;

    mapping (bytes32 => address) tokenMappingByKash;
    mapping (bytes32 => address) tokenMappingByTarget;

    function initialize(address poolAddr,address mosAddr,uint256 chainid,address messengerAddr) external {
        KashUUPSUpgradeable._init();
        pool = IPool(poolAddr);
        mos = IMOSV3(mosAddr);
        controllerChainid = chainid;
        gasLimit = 5000;
        messenger = messengerAddr;
    }

    function handleSupply(
        bytes32 sideAsset,
        bytes32 suppler,
        uint256 amount,
        bytes calldata data
    ) external override {
        uint16 referralCode = abi.decode(data,(uint16));
        pool.supply(tokenMappingByKash[sideAsset],amount,Utils.fromBytes32(suppler),referralCode);
    }

    function handleRepay(
        bytes32 sideAsset,
        bytes32 borrower,
        uint256 amount,
        bytes calldata data
    ) external override {
        uint256 interestRateMode = abi.decode(data,(uint256));
        pool.repay(tokenMappingByKash[sideAsset],amount,interestRateMode,Utils.fromBytes32(borrower));
    }

    function handleWithdraw(
        address caller,
        uint256 chainId,
        address asset, 
        bytes32 receiver,
        uint256 amount
    ) external override {
        bytes32 sideAsset = keccak256(abi.encode(chainId, asset));
        bytes memory data = abi.encodeWithSignature(
            "function withdraw(address,address,uint256)",
            tokenMappingByTarget[sideAsset],
            Utils.fromBytes32(receiver),
            amount
        );

        _callMos(data);
    }

    function handleBorrow(
        address caller,
        uint256 chainId,
        address asset, 
        bytes32 borrower,
        uint256 amount
    ) external override {
        bytes32 sideAsset = keccak256(abi.encode(chainId, asset));
        bytes memory data = abi.encodeWithSignature(
            "function withdraw(address,address,uint256)",
            tokenMappingByTarget[sideAsset],
            Utils.fromBytes32(borrower),
            amount
        );

        _callMos(data);
    }

    // Call MOS
    function _callMos(bytes memory data) internal {
        IMOSV3.CallData memory cData = IMOSV3.CallData(
            Utils.toBytes(controller),
            data,
            gasLimit,
            0
        );
        bool success = IMOSV3(mos).transferOut(controllerChainid, cData);
        if (!success) revert CALL_MOS_FAIL();
    }

    function setController(address controllerAddr,uint256 chainid) external onlyOwner {
        controller = controllerAddr;
        controllerChainid = chainid;
    }

    function setPool(address poolAddr) external onlyOwner {
        pool = IPool(poolAddr);
    }

    function setMos(address mosAddr) external onlyOwner {
        mos = IMOSV3(mosAddr);
    }

    function setMappingByKash(bytes32 sideAsset,address tokenAddr) external onlyOwner {
        tokenMappingByKash[sideAsset] = tokenAddr;
    }

    function setMappingByTarget(bytes32 sideAsset,address tokenAddr) external onlyOwner {
        tokenMappingByTarget[sideAsset] = tokenAddr;
    }

    function setGasLimit(uint256 limit) external onlyOwner {
        gasLimit = limit;
    }

    function setMessenger(address messengerAddr) external onlyOwner {
        messenger = messengerAddr;
    }
}