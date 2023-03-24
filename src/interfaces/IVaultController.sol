// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IVaultController {
    function supply(address token, uint256 amount, bytes calldata customData) external;

    function supplyETH(bytes calldata customData) external payable;

    function repay(address token, uint256 amount, bytes calldata customData) external;

    function repayETH(bytes calldata customData) external payable;

    function withdraw(address token, address to, uint256 amount) external;

    function borrow(address token, address to, uint256 amount) external;

    function migrate(address token, address newVault) external;

    function setVault(address token, address vault) external;

    function setGasLimit(uint256 limit) external;
}
