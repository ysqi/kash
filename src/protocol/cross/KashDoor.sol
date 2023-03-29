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
import "../../protocol/lib/helpers/Errors.sol";

contract KashDoor is KashUUPSUpgradeable, IKashCrossDoor {
    IMOSV3 public mos;
    address public kashPool;
    address public messenger;
    uint256 public gasLimit;

    mapping(bytes32 => address) public mTokens;
    mapping(address mtoken => mapping(uint256 chainid => bytes32 targetToken)) public
        chainTokenMapping;
    mapping(uint256 chainid => bytes controller) public controllers;
    mapping(bytes32 => uint256) public balance;

    // the mail box for cross chain.
    mapping(bytes32 => bool) public receivedMail;
    mapping(address => uint256) public crossMailNonce;

    modifier onlyMessenger() {
        // TODO: just for test
        if (messenger != address(0) && msg.sender != messenger) revert CALLER_NOT_MESSENGER();
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

    function initialize(address mosAddr, address messengerAddr) external initializer {
        KashUUPSUpgradeable._init();
        mos = IMOSV3(mosAddr);
        gasLimit = 50000;
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

    function handleSupply(
        bytes32 sideAsset,
        bytes32 suppler,
        uint256 amount,
        bytes calldata data,
        uint256 nonce
    ) external override /* onlyMessenger */ {
        bytes32 msgId = keccak256(abi.encode("supply", sideAsset, suppler, amount, data, nonce));
        if (receivedMail[msgId]) revert Errors.REPEAT_CROSS_MSG();
        receivedMail[msgId] = true;

        uint16 referralCode = abi.decode(data, (uint16));
        address user = Utils.fromBytes32(suppler);

        _mintAndApprove(sideAsset, amount);

        IPool(kashPool).supply(mTokens[sideAsset], amount, user, referralCode);
        balance[sideAsset] += amount;
    }

    function handleRepay(
        bytes32 sideAsset,
        bytes32 borrower,
        uint256 amount,
        bytes calldata data,
        uint256 nonce
    ) external override /* onlyMessenger */ {
        bytes32 msgId = keccak256(abi.encode("repay", sideAsset, borrower, amount, data, nonce));
        if (receivedMail[msgId]) revert Errors.REPEAT_CROSS_MSG();
        receivedMail[msgId] = true;

        uint256 interestRateMode = abi.decode(data, (uint256));

        _mintAndApprove(sideAsset, amount);

        IPool(kashPool).repay(
            mTokens[sideAsset], amount, interestRateMode, Utils.fromBytes32(borrower)
        );
        balance[sideAsset] += amount;
    }

    function handleWithdraw(
        address caller,
        uint256 tragetChainId,
        address ktoken,
        bytes32 receiver,
        uint256 amount
    ) external override /*onlyKashPool*/ {
        // if (balance[sideAsset] < amount) revert INSUFFICIENT_VAULT_FUNDS();
        bytes memory data = abi.encodeWithSignature(
            "withdraw(address,address,uint256,uint256)",
            Utils.fromBytes32(chainTokenMapping[ktoken][tragetChainId]),
            Utils.fromBytes32(receiver),
            amount,
            crossMailNonce[caller]
        );
        crossMailNonce[caller]++;

        // burn mtoken
        MToken(ktoken).burn(amount);

        bytes32 targetToken = chainTokenMapping[ktoken][tragetChainId];
        if (targetToken == 0x0) revert Errors.MISSING_CHAINTOKENMAPPING();

        bytes32 sideAsset = keccak256(abi.encode(tragetChainId, targetToken));
        if (balance[sideAsset] < amount) {
            revert Errors.INSUFFICIENT_VAULT_FUNDS();
        }
        balance[sideAsset] -= amount;

        _callMos(tragetChainId, controllers[tragetChainId], data);
    }

    function handleBorrow(
        address caller,
        uint256 chainId,
        address asset,
        bytes32 borrower,
        uint256 amount
    ) external override /*onlyKashPool*/ {
        // if (balance[sideAsset] < amount) revert INSUFFICIENT_VAULT_FUNDS();
        bytes memory data = abi.encodeWithSignature(
            "withdraw(address,address,uint256,uint256)",
            Utils.fromBytes32(chainTokenMapping[asset][chainId]),
            Utils.fromBytes32(borrower),
            amount,
            crossMailNonce[caller]
        );
        crossMailNonce[caller]++;

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
            IMOSV3(mos).getMessageFee(controllerChainid, address(0), gasLimit);
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
        IMOSV3(mos).addRemoteCaller(chainId, controller, true);
        controllers[chainId] = controller;
    }

    function withdrawFee(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function execute(address target, bytes memory data) external onlyOwner {
        (bool success,) = target.call(data);
        require(success, "F");
    }

    receive() external payable { }
}
