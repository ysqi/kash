// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/proxy/utils/Initializable.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "solmate/tokens/WETH.sol";
import "./Vault.sol";
import "./interface/IMOSV3.sol";
import "./utils/Utils.sol";
import "./interface/IVaultController.sol";
import "./Error.sol";

contract VaultController is IVaultController, Initializable {
    using SafeERC20 for IERC20;

    address public owner;
    address public messenger;
    address public mos;
    address public kash;
    uint256 public kashChainid;
    uint256 public gasLimit;
    WETH public weth;
    mapping(address => address) public vaults;

    event CreateVault(address indexed token, address vault);
    event Deposit(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);
    event Migrate(address indexed token, address oldVault, address newVault);

    modifier onlyOwner() {
        if (msg.sender != owner) revert CALLER_NOT_OWNER();
        _;
    }

    modifier onlyMessenger() {
        if (msg.sender != messenger) revert CALLER_NOT_MESSENGER();
        _;
    }

    modifier checkVault(address token) {
        if (vaults[token] == address(0)) revert VAULT_NOT_EXISTS();
        _;
    }

    function initialization(
        address messengerAddress,
        address kashAddress,
        uint256 chainid,
        address payable wethAddress
    ) external initializer {
        owner = msg.sender;
        messenger = messengerAddress;
        kash = kashAddress;
        kashChainid = chainid;
        weth = WETH(wethAddress);
        gasLimit = 5000;
    }

    function setVault(address token, address vault) external onlyOwner {
        vaults[token] = vault;
    }

    function deposit(address token, uint256 amount) external checkVault(token) {
        IERC20(token).safeTransferFrom(msg.sender, vaults[token], amount);
        _callMosDeposit(msg.sender, token, amount);
    }

    function depositETH() external payable checkVault(address(weth)) {
        weth.deposit{ value: msg.value }();
        weth.transfer(vaults[address(weth)], msg.value);
        _callMosDeposit(msg.sender, address(weth), msg.value);
    }

    // Call MOS
    function _callMosDeposit(address user, address token, uint256 amount) internal {
        bytes memory data =
            abi.encodeWithSignature("deposit(address,address,uint256)", user, token, amount);
        IMOSV3.CallData memory cData = IMOSV3.CallData(Utils.toBytes(kash), data, gasLimit, 0);
        bool success = IMOSV3(mos).transferOut(kashChainid, cData);
        if (!success) revert CALL_MOS_FAIL();
        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, address to, uint256 amount)
        external
        onlyMessenger
        checkVault(token)
    {
        if (token == address(weth)) {
            Vault(vaults[address(weth)]).withdraw(address(this), amount);
            weth.withdraw(amount);
            (bool success,) = to.call{ value: amount }("");
            if (!success) revert WITHDRAW_ETH_FAIL();
        } else {
            Vault(vaults[token]).withdraw(to, amount);
        }

        emit Withdraw(to, token, amount);
    }

    function setMessenger(address messengerAddress) external onlyOwner {
        messenger = messengerAddress;
    }

    function setMos(address mosAddress) external onlyOwner {
        mos = mosAddress;
    }

    function setKash(address kashAddress, uint256 chainId) external onlyOwner {
        kash = kashAddress;
        kashChainid = chainId;
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
