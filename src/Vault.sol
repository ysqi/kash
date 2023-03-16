// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/access/Ownable.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    address public token;

    // constructor(address _token) {
    //     token = _token;
    //     controller = msg.sender;
    // }

    function initialize(address _token) external {
        require(token == address(0), "Already initialized");
        token = _token;
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        IERC20(token).safeTransfer(_to, _amount);
    }

    function migrate(address _newVault) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(_newVault, balance);
    }

    // 找回转错的Token，禁止取回金库的Token
    function withdrawOtherToken(address _token, address _to, uint256 _amount) external onlyOwner {
        require(_token != token, "Token not allowed");
        IERC20(_token).safeTransfer(_to, _amount);
    }
}
