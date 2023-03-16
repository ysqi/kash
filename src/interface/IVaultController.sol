// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IVaultController {
    function createVault(address _token) external returns (address);

    function deposit(address _token, uint256 _amount) external;

    function withdraw(address _token, address _to, uint256 _amount) external;

    function migrate(address _token, address _newVault) external;

    function withdrawOtherToken(
        address _vault,
        address _token,
        address _to,
        uint256 _amount
    ) external;
}
