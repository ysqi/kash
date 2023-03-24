// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "solmate/tokens/WETH.sol";
import "./Vault.sol";
import "../interfaces/IMOSV3.sol";
import "../utils/Utils.sol";
import "../interfaces/IVaultController.sol";
import "../protocol/lib/upgradeable/KashUUPSUpgradeable.sol";
import "./Error.sol";

import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract VaultController is IVaultController, KashUUPSUpgradeable {
    using SafeERC20 for IERC20;

    address public messenger;
    address public mos;
    address public door;
    uint256 public doorChainid;
    uint256 public gasLimit;
    WETH public weth;
    mapping(address => address) public vaults;

    event CreateVault(address indexed token, address vault);
    event Supply(address indexed user, address token, uint256 amount);
    event Repay(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);
    event Borrow(address indexed user, address token, uint256 amount);
    event Migrate(address indexed token, address oldVault, address newVault);

    modifier onlyMessenger() {
        if (msg.sender != messenger) revert CALLER_NOT_MESSENGER();
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
    ) external {
        KashUUPSUpgradeable._init();
        messenger = messengerAddress;
        door = doorAddress;
        doorChainid = chainid;
        weth = WETH(wethAddress);
        mos = mosAddr;
        gasLimit = 5000;
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
        bytes memory data = abi.encodeWithSignature(
            "handleSupply(bytes32,bytes32,uint256,bytes)",
            sideAsset,
            Utils.toBytes32(msg.sender),
            amount,
            customData
        );
        _callMos(data);
        emit Supply(msg.sender, token, amount);
    }

    function supplyETH(bytes calldata customData) external payable checkVault(address(weth)) {
        weth.deposit{ value: msg.value }();
        weth.transfer(vaults[address(weth)], msg.value);
        bytes32 sideAsset = keccak256(abi.encode(block.chainid, address(weth)));
        bytes memory data = abi.encodeWithSignature(
            "handleSupply(bytes32,bytes32,uint256,bytes)",
            sideAsset,
            Utils.toBytes32(msg.sender),
            msg.value,
            customData
        );
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
            "handleRepay(bytes32,bytes32,uint256,bytes)",
            sideAsset,
            Utils.toBytes32(msg.sender),
            amount,
            customData
        );
        _callMos(data);
        emit Repay(msg.sender, token, amount);
    }

    function repayETH(bytes calldata customData) external payable checkVault(address(weth)) {
        bytes32 sideAsset = keccak256(abi.encode(block.chainid, address(weth)));
        bytes memory data = abi.encodeWithSignature(
            "handleRepay(bytes32,bytes32,uint256,bytes)",
            sideAsset,
            Utils.toBytes32(msg.sender),
            msg.value,
            customData
        );
        _callMos(data);
        emit Repay(msg.sender, address(weth), msg.value);
    }

    // Call MOS
    function _callMos(bytes memory data) internal {
        IMOSV3.CallData memory cData = IMOSV3.CallData(Utils.toBytes(door), data, gasLimit, 0);
        bool success = IMOSV3(mos).transferOut(doorChainid, cData);
        if (!success) revert CALL_MOS_FAIL();
    }

    function withdraw(address token, address to, uint256 amount)
        external
        onlyMessenger
        checkVault(token)
    {
        _withdraw(token, to, amount);
        emit Withdraw(to, token, amount);
    }

    function borrow(address token, address to, uint256 amount)
        external
        onlyMessenger
        checkVault(token)
    {
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
}
