// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface IPriceOracle {
    function getLastPrice(address asset)
        external
        view
        returns (uint256 updateAt, uint256 wadPrice);
}
