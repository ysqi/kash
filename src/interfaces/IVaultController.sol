// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IVaultController {
    function deposit(address token, uint256 amount) external;

    function depositETH() external payable;

    function withdraw(address token, address to, uint256 amount) external;

    function migrate(address token, address newVault) external;

    function setVault(address token, address vault) external;

    function setGasLimit(uint256 limit) external;
}
