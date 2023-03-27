// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../protocol/lib/upgradeable/KashUUPSUpgradeable.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IKashCrossDoor.sol";
import "../../utils/Utils.sol";
import "../../interfaces/IMOSV3.sol";
import "./Error.sol";
import "./MToken.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "../../protocol/lib/KashDataTypes.sol";

contract KashDoor is KashUUPSUpgradeable, IKashCrossDoor {
    IMOSV3 public mos;
    address public kashPool;
    address public messenger;
    uint256 public gasLimit;

    mapping(bytes32 => address) public mTokens;
    mapping(address mtoken => mapping(uint256 chainid => bytes32 targetToken)) chainTokenMapping;
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

    function initialize(address mosAddr, address messengerAddr)
        external
        initializer
    {
        KashUUPSUpgradeable._init();
        mos = IMOSV3(mosAddr);
        gasLimit = 5000;
        messenger = messengerAddr;
    }

    function _mintAndApprove(bytes32 sideAsset, uint256 amount) internal {
        // mint
        MToken(mTokens[sideAsset]).mint(amount);
        //approve
        ReserveData memory reserveData = IPool(kashPool).getReserveData(mTokens[sideAsset]);
        address creditToken = reserveData.creditTokenAddress;
        MToken(mTokens[sideAsset]).approve(creditToken, amount);
    }

    function handleSupply(bytes32 sideAsset, bytes32 suppler, uint256 amount, bytes calldata data)
        external
        override /* onlyMessenger */
    {
        uint16 referralCode = abi.decode(data, (uint16));
        address user = Utils.fromBytes32(suppler);

        _mintAndApprove(sideAsset, amount);

        IPool(kashPool).supply(mTokens[sideAsset], amount, user, referralCode);
        balance[sideAsset] += amount;
    }

    function handleRepay(bytes32 sideAsset, bytes32 borrower, uint256 amount, bytes calldata data)
        external
        override /* onlyMessenger */
    {
        uint256 interestRateMode = abi.decode(data, (uint256));

        _mintAndApprove(sideAsset, amount);

        IPool(kashPool).repay(
            mTokens[sideAsset], amount, interestRateMode, Utils.fromBytes32(borrower)
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
        // if (balance[sideAsset] < amount) revert INSUFFICIENT_VAULT_FUNDS();
        bytes memory data = abi.encodeWithSignature(
            "function withdraw(address,address,uint256)",
            Utils.fromBytes32(chainTokenMapping[asset][chainId]),
            Utils.fromBytes32(receiver),
            amount
        );

        // burn mtoken
        MToken(asset).burn(amount);

        _callMos(chainId, controllers[chainId], data);

        bytes32 targetToken = chainTokenMapping[asset][chainId];
        bytes32 sideAsset = keccak256(abi.encode(chainId, targetToken));
        balance[sideAsset] -= amount;
    }

    function handleBorrow(
        address caller,
        uint256 chainId,
        address asset,
        bytes32 borrower,
        uint256 amount
    ) external override onlyKashPool {
        // if (balance[sideAsset] < amount) revert INSUFFICIENT_VAULT_FUNDS();
        bytes memory data = abi.encodeWithSignature(
            "function withdraw(address,address,uint256)",
            Utils.fromBytes32(chainTokenMapping[asset][chainId]),
            Utils.fromBytes32(borrower),
            amount
        );

        MToken(asset).burn(amount);

        _callMos(chainId, controllers[chainId], data);
        bytes32 targetToken = chainTokenMapping[asset][chainId];
        bytes32 sideAsset = keccak256(abi.encode(chainId, targetToken));
        balance[sideAsset] -= amount;
    }

    // Call MOS
    function _callMos(uint256 controllerChainid, bytes memory controller, bytes memory data)
        internal
    {
        // IMOSV3.CallData memory cData = IMOSV3.CallData(controller, data, gasLimit, 0);
        IMOSV3.MessageData memory mData =
            IMOSV3.MessageData(false, IMOSV3.MessageType.CALLDATA, controller, data, gasLimit, 0);

        bytes memory mDataBytes = abi.encode(mData);

        (uint256 amount, address receiverAddress) =
            IMOSV3(mos).getMessageFee(controllerChainid, address(0), 500000);
        bool success =
            IMOSV3(mos).transferOut{ value: amount }(controllerChainid, mDataBytes, address(0));
        if (!success) revert CALL_MOS_FAIL();
    }

    function setPool(address poolAddr) external onlyOwner {
        kashPool = poolAddr;
    }

    function setMos(address mosAddr) external onlyOwner {
        mos = IMOSV3(mosAddr);
    }

    function setMtoken(bytes32 sideAsset, address tokenAddr) external onlyOwner {
        mTokens[sideAsset] = tokenAddr;
    }

    function setChainTokenMapping(address mTokenAddr, uint256 chainId, bytes32 targetToken)
        external
        onlyOwner
    {
        chainTokenMapping[mTokenAddr][chainId] = targetToken;
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
