// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "./Error.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    address public token;
    address public controller;

    constructor(address tokenAddress, address controllerAddress) {
        token = tokenAddress;
        controller = controllerAddress;
    }

    modifier onlyController() {
        if (msg.sender != controller) revert CALLER_NOT_CONTROLLER();
        _;
    }

    function withdraw(address to, uint256 amount) external onlyController {
        IERC20(token).safeTransfer(to, amount);
    }

    function migrate(address _newVault) external onlyController {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(_newVault, balance);
    }

    function setController(address controllerAddress) external onlyOwner {
        controller = controllerAddress;
    }
}
