// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "@openzeppelin/proxy/utils/Initializable.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./Vault.sol";
import "./interface/IMOSV3.sol";
import "./utils/Utils.sol";

contract VaultController is Initializable {
    using SafeERC20 for IERC20;

    address public owner;
    address public messenger;
    address public mos;
    address public kash;
    uint256 public kashChainid;
    mapping(address => address) public vaults;

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

    function initialization(address _messenger, address _kash, uint256 _kashChainid)
        external
        initializer
    {
        owner = msg.sender;
        messenger = _messenger;
        kash = _kash;
        kashChainid = _kashChainid;
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

    function depositERC20(address _token, uint256 _amount) external {
        IERC20(_token).safeTransferFrom(msg.sender, vaults[_token], _amount);
        // 调用MOS传递消息给Kash
        bytes memory data =
            abi.encodeWithSignature("deposit(address,address,uint256)", msg.sender, _token, _amount);
        IMOSV3.CallData memory cData = IMOSV3.CallData(Utils.toBytes(kash), data, 50000, 0);
        require(IMOSV3(mos).transferOut(kashChainid, cData), "send request failed");

        emit Deposit(msg.sender, _token, _amount);
    }

    function withdraw(address _token, address _to, uint256 _amount) external onlyMessenger {
        Vault(vaults[_token]).withdraw(_to, _amount);

        emit Withdraw(_to, _token, _amount);
    }

    // 迁移金库
    function migrate(address _token, address _newVault) external onlyOwner {
        require(vaults[_token] != address(0), "Vault not exists");
        address oldVault = vaults[_token];
        Vault(oldVault).migrate(_newVault);
        vaults[_token] = _newVault;
        emit Migrate(_token, oldVault, _newVault);
    }

    // 找回转错的Token，禁止取回金库的Token
    function withdrawOtherToken(address _vault, address _token, address _to, uint256 _amount)
        external
        onlyOwner
    {
        Vault(_vault).withdrawOtherToken(_token, _to, _amount);
    }
}
