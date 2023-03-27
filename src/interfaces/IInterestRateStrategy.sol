// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface IInterestRateStrategy {
    function borrowRate(uint256 cash, uint256 borrows, uint256 reserves)
        external
        view
        returns (uint256);

    function supplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);

    function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves)
        external
        view
        returns (uint256);
}
