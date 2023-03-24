// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../protocol/lib/upgradeable/KashUUPSUpgradeable.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IKashCrossDoor.sol";
import "../utils/Utils.sol";
import "../interfaces/IMOSV3.sol";
import "./Error.sol";

contract KashDoor is KashUUPSUpgradeable, IKashCrossDoor {
    IMOSV3 public mos;
    address public kashPool;
    address public messenger;
    uint256 public gasLimit;

    mapping(bytes32 => address) public tokenMappingByKash;
    mapping(bytes32 => bytes32) public tokenMappingByTarget;
    mapping(uint256 chainid => bytes controller) public controllers;
    mapping(bytes32 => uint256) public balance;

    modifier onlyMessenger() {
        if (msg.sender != messenger) revert CALLER_NOT_MESSENGER();
        _;
    }

    modifier onlyKashPool() {
        if (msg.sender != kashPool) revert CALLER_NOT_KASHPOOL();
        _;
    }

    modifier checkSupportedChain(uint256 chainId) {
        if (controllers[chainId].length == 0) revert CHAIN_NOT_SUPPORTED();
        _;
    }

    function initialize(address mosAddr, address messengerAddr, address kashPoolAddr) external {
        KashUUPSUpgradeable._init();
        mos = IMOSV3(mosAddr);
        gasLimit = 5000;
        messenger = messengerAddr;
        kashPool = kashPoolAddr;
    }

    function handleSupply(bytes32 sideAsset, bytes32 suppler, uint256 amount, bytes calldata data)
        external
        override /* onlyMessenger */
    {
        uint16 referralCode = abi.decode(data, (uint16));
        address user = Utils.fromBytes32(suppler);

        IPool(kashPool).supply(tokenMappingByKash[sideAsset], amount, user, referralCode);
        balance[sideAsset] += amount;
    }

    function handleRepay(bytes32 sideAsset, bytes32 borrower, uint256 amount, bytes calldata data)
        external
        override /* onlyMessenger */
    {
        uint256 interestRateMode = abi.decode(data, (uint256));
        IPool(kashPool).repay(
            tokenMappingByKash[sideAsset], amount, interestRateMode, Utils.fromBytes32(borrower)
        );
        balance[sideAsset] += amount;
    }

    function handleWithdraw(
        address caller,
        uint256 chainId,
        address asset,
        bytes32 receiver,
        uint256 amount
    ) external override onlyKashPool {
        bytes32 sideAsset = keccak256(abi.encode(chainId, asset));
        if (balance[sideAsset] < amount) revert INSUFFICIENT_VAULT_FUNDS();
        bytes memory data = abi.encodeWithSignature(
            "function withdraw(address,address,uint256)",
            Utils.fromBytes32(tokenMappingByTarget[sideAsset]),
            Utils.fromBytes32(receiver),
            amount
        );

        _callMos(chainId, controllers[chainId], data);

        balance[sideAsset] -= amount;
    }

    function handleBorrow(
        address caller,
        uint256 chainId,
        address asset,
        bytes32 borrower,
        uint256 amount
    ) external override onlyKashPool {
        bytes32 sideAsset = keccak256(abi.encode(chainId, asset));
        if (balance[sideAsset] < amount) revert INSUFFICIENT_VAULT_FUNDS();
        bytes memory data = abi.encodeWithSignature(
            "function withdraw(address,address,uint256)",
            Utils.fromBytes32(tokenMappingByTarget[sideAsset]),
            Utils.fromBytes32(borrower),
            amount
        );

        _callMos(chainId, controllers[chainId], data);
        balance[sideAsset] -= amount;
    }

    // Call MOS
    function _callMos(uint256 controllerChainid, bytes memory controller, bytes memory data)
        internal
    {
        IMOSV3.CallData memory cData = IMOSV3.CallData(controller, data, gasLimit, 0);
        bool success = IMOSV3(mos).transferOut(controllerChainid, cData);
        if (!success) revert CALL_MOS_FAIL();
    }

    function setPool(address poolAddr) external onlyOwner {
        kashPool = poolAddr;
    }

    function setMos(address mosAddr) external onlyOwner {
        mos = IMOSV3(mosAddr);
    }

    function setMappingByKash(bytes32 sideAsset, address tokenAddr) external onlyOwner {
        tokenMappingByKash[sideAsset] = tokenAddr;
    }

    function setMappingByTarget(bytes32 sideAsset, bytes32 tokenAddr) external onlyOwner {
        tokenMappingByTarget[sideAsset] = tokenAddr;
    }

    function setGasLimit(uint256 limit) external onlyOwner {
        gasLimit = limit;
    }

    function setMessenger(address messengerAddr) external onlyOwner {
        messenger = messengerAddr;
    }

    function setController(uint256 chainId, bytes calldata controller) external onlyOwner {
        controllers[chainId] = controller;
    }
}
