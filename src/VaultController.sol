// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/proxy/utils/Initializable.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "solmate/tokens/WETH.sol";
import "./Vault.sol";
import "./interface/IMOSV3.sol";
import "./utils/Utils.sol";
import "./interface/IVaultController.sol";

contract VaultController is IVaultController,Initializable {
    using SafeERC20 for IERC20;

    address public owner;
    address public messenger;
    address public mos;
    address public kash;
    uint256 public kashChainid;
    uint256 public gasLimit;
    WETH    public weth;
    mapping(address => address) public vaults;
    mapping (address => bool) supportedTokens;

    event CreateVault(address indexed token, address vault);
    event Deposit(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);
    event Migrate(address indexed token, address oldVault, address newVault);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyMessenger() {
        require(msg.sender == messenger, "Caller is not the messenger");
        _;
    }

    function initialization(address _messenger, address _kash, uint256 _kashChainid,address payable _weth)
        external
        initializer
    {
        owner = msg.sender;
        messenger = _messenger;
        kash = _kash;
        kashChainid = _kashChainid;
        weth = WETH(_weth);
        gasLimit = 5000;
        supportedTokens[_weth] = true;
    }

    function setSupportedTokens(address _token,bool _enable) external onlyOwner {
        supportedTokens[_token] = _enable;
    }

    function createVault(address _token) external onlyOwner returns (address) {
        require(vaults[_token] == address(0), "Vault already exists");
        bytes memory bytecode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token));
        address vault;
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        Vault(vault).initialize(_token);
        vaults[_token] = vault;

        emit CreateVault(_token, vault);
        return vault;
    }

    function deposit(address _token, uint256 _amount) external {
        require(supportedTokens[_token],"Token not supported");
        IERC20(_token).safeTransferFrom(msg.sender, vaults[_token], _amount);
        _callMosDeposit(msg.sender,_token,_amount);
    }

    function depositETH() external payable {
        weth.deposit{value:msg.value}();
        weth.transfer(vaults[address(weth)],msg.value);
        _callMosDeposit(msg.sender, address(weth), msg.value);
    }

    // Call MOS
    function _callMosDeposit(address _user,address _token,uint256 _amount) internal {
        bytes memory data =
            abi.encodeWithSignature("deposit(address,address,uint256)", _user, _token, _amount);
        IMOSV3.CallData memory cData = IMOSV3.CallData(Utils.toBytes(kash), data, gasLimit, 0);
        require(IMOSV3(mos).transferOut(kashChainid, cData), "send request failed");
        emit Deposit(msg.sender, _token, _amount);
    }

    function withdraw(address _token, address _to, uint256 _amount) external onlyMessenger {
        if (_token == address(weth)) {
            Vault(vaults[address(weth)]).withdraw(address(this), _amount);
            weth.withdraw(_amount);
            (bool success,) = _to.call{value: _amount}("");
            require(success,"Withdraw ETH fail");
        } else {
            Vault(vaults[_token]).withdraw(_to, _amount);
        }

        emit Withdraw(_to, _token, _amount);
    }

    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }

    // Migrate vault
    function migrate(address _token, address _newVault) external onlyOwner {
        require(vaults[_token] != address(0), "Vault not exists");
        address oldVault = vaults[_token];
        Vault(oldVault).migrate(_newVault);
        vaults[_token] = _newVault;
        emit Migrate(_token, oldVault, _newVault);
    }

    // Extract the wrong token
    function withdrawOtherToken(address _vault, address _token, address _to, uint256 _amount)
        external
        onlyOwner
    {
        Vault(_vault).withdrawOtherToken(_token, _to, _amount);
    }
}
