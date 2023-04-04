// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "solmate/tokens/WETH.sol";
import "./Vault.sol";
import "../../interfaces/IMOSV3.sol";
import "../../utils/Utils.sol";
import "../../interfaces/IVaultController.sol";
import "../../protocol/lib/upgradeable/KashUUPSUpgradeable.sol";
import "../../protocol/lib/helpers/Errors.sol";
import "./Error.sol";

import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract VaultController is IVaultController, KashUUPSUpgradeable {
    event ReceivedMail(bytes32 indexed msgId);

    using SafeERC20 for IERC20;

    address public messenger;
    address public mos;
    address public door;
    uint256 public doorChainid;
    uint256 public gasLimit;
    WETH public weth;
    mapping(address => address) public vaults;

    // the mail box for cross chain.
    mapping(bytes32 => bool) public receivedMail;
    mapping(address => uint256) public crossMailNonce;

    event CreateVault(address indexed token, address vault);
    event Supply(address indexed user, address token, uint256 amount);
    event Repay(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);
    event Borrow(address indexed user, address token, uint256 amount);
    event Migrate(address indexed token, address oldVault, address newVault);

    modifier onlyMessenger() {
        if (messenger != address(0) && msg.sender != messenger) revert CALLER_NOT_MESSENGER();
        _;
    }

    modifier checkVault(address token) {
        if (vaults[token] == address(0)) revert VAULT_NOT_EXISTS();
        _;
    }

    function initialize(
        address messengerAddress,
        address doorAddress,
        uint256 chainid,
        address payable wethAddress,
        address mosAddr
    ) external initializer {
        KashUUPSUpgradeable._init();
        messenger = messengerAddress;
        door = doorAddress;
        doorChainid = chainid;
        weth = WETH(wethAddress);
        mos = mosAddr;
        gasLimit = 50000;
    }

    function setVault(address token, address vault) external onlyOwner {
        vaults[token] = vault;
    }

    function supply(address token, uint256 amount, bytes calldata customData)
        external
        checkVault(token)
    {
        IERC20(token).safeTransferFrom(msg.sender, vaults[token], amount);
        bytes32 sideAsset = keccak256(abi.encode(block.chainid, token));
        bytes32 suppler = Utils.toBytes32(msg.sender);
        bytes memory data = customData;
        uint256 nonce = crossMailNonce[msg.sender];
        bytes32 msgId = keccak256(abi.encode("supply", sideAsset, suppler, amount, data, nonce));

        bytes memory callData = abi.encodeWithSignature(
            "handleSupply(bytes32,bytes32,uint256,bytes,uint256)",
            sideAsset,
            suppler,
            amount,
            data,
            nonce
        );

        crossMailNonce[msg.sender]++;
        _callMos(callData);
        emit Supply(msg.sender, token, amount);
    }

    function supplyETH(bytes calldata customData) external payable checkVault(address(weth)) {
        weth.deposit{ value: msg.value }();
        weth.transfer(vaults[address(weth)], msg.value);
        bytes32 sideAsset = keccak256(abi.encode(block.chainid, address(weth)));
        bytes memory data = abi.encodeWithSignature(
            "handleSupply(bytes32,bytes32,uint256,bytes,uint256)",
            sideAsset,
            Utils.toBytes32(msg.sender),
            msg.value,
            customData,
            crossMailNonce[msg.sender]
        );
        crossMailNonce[msg.sender]++;
        _callMos(data);
        emit Supply(msg.sender, address(weth), msg.value);
    }

    function repay(address token, uint256 amount, bytes calldata customData)
        external
        checkVault(token)
    {
        IERC20(token).safeTransferFrom(msg.sender, vaults[token], amount);
        bytes32 sideAsset = keccak256(abi.encode(block.chainid, token));
        bytes memory data = abi.encodeWithSignature(
            "handleRepay(bytes32,bytes32,uint256,bytes,uint256)",
            sideAsset,
            Utils.toBytes32(msg.sender),
            amount,
            customData,
            crossMailNonce[msg.sender]
        );

        crossMailNonce[msg.sender]++;
        _callMos(data);
        emit Repay(msg.sender, token, amount);
    }

    function repayETH(bytes calldata customData) external payable checkVault(address(weth)) {
        bytes32 sideAsset = keccak256(abi.encode(block.chainid, address(weth)));
        bytes memory data = abi.encodeWithSignature(
            "handleRepay(bytes32,bytes32,uint256,bytes,uint256)",
            sideAsset,
            Utils.toBytes32(msg.sender),
            msg.value,
            customData,
            crossMailNonce[msg.sender]
        );
        crossMailNonce[msg.sender]++;
        _callMos(data);
        emit Repay(msg.sender, address(weth), msg.value);
    }

    // Call MOS
    function _callMos(bytes memory data) internal {
        // IMOSV3.CallData memory cData = IMOSV3.CallData(Utils.toBytes(door), data, gasLimit, 0);
        IMOSV3.MessageData memory mData = IMOSV3.MessageData(
            false, IMOSV3.MessageType.CALLDATA, Utils.toBytes(door), data, gasLimit, 0
        );
        bytes memory mDataBytes = abi.encode(mData);
        (uint256 amount, address receiverAddress) =
            IMOSV3(mos).getMessageFee(doorChainid, address(0), gasLimit);
        bool success = IMOSV3(mos).transferOut{ value: amount }(doorChainid, mDataBytes, address(0));
        if (!success) revert CALL_MOS_FAIL();
    }

    function withdraw(address token, address to, uint256 amount, uint256 nonce)
        external
        onlyMessenger
        checkVault(token)
    {
        bytes32 msgId = keccak256(abi.encode("withdraw", block.chainid, token, to, amount, nonce));
        if (receivedMail[msgId]) revert Errors.REPEAT_CROSS_MSG();
        receivedMail[msgId] = true;

        _withdraw(token, to, amount);
        emit Withdraw(to, token, amount);
        emit ReceivedMail(msgId);
    }

    function borrow(address token, address to, uint256 amount, uint256 nonce)
        external
        onlyMessenger
        checkVault(token)
    {
        bytes32 msgId = keccak256(abi.encode("borrow", block.chainid, token, to, amount, nonce));
        if (receivedMail[msgId]) revert Errors.REPEAT_CROSS_MSG();
        receivedMail[msgId] = true;

        _withdraw(token, to, amount);
        emit Borrow(to, token, amount);
    }

    function _withdraw(address token, address to, uint256 amount) internal {
        if (token == address(weth)) {
            Vault(vaults[address(weth)]).withdraw(address(this), amount);
            weth.withdraw(amount);
            (bool success,) = to.call{ value: amount }("");
            if (!success) revert WITHDRAW_ETH_FAIL();
        } else {
            Vault(vaults[token]).withdraw(to, amount);
        }
    }

    function setMessenger(address messengerAddress) external onlyOwner {
        messenger = messengerAddress;
    }

    function setMos(address mosAddress) external onlyOwner {
        mos = mosAddress;
    }

    function setDoor(address doorAddress, uint256 chainId) external onlyOwner {
        IMOSV3(mos).addRemoteCaller(chainId, abi.encodePacked(doorAddress), true);
        door = doorAddress;
        doorChainid = chainId;
    }

    function setGasLimit(uint256 limit) external onlyOwner {
        gasLimit = limit;
    }

    function setWETH(address payable wethAddress) external onlyOwner {
        weth = WETH(wethAddress);
    }

    // Migrate vault
    function migrate(address token, address newVault) external onlyOwner checkVault(token) {
        address oldVault = vaults[token];
        Vault(oldVault).migrate(newVault);
        vaults[token] = newVault;
        emit Migrate(token, oldVault, newVault);
    }

    function withdrawFee(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable { }
}
