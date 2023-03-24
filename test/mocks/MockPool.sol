// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

struct MokeReserveData {
    address kTokenAddress;
}

contract MockPool {
    constructor() { }

    event Repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf);

    event Supply(
        address caller, address asset, uint256 amount, address onBehalfOf, uint16 referralCode
    );

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256)
    {
        emit Repay(asset, amount, interestRateMode, onBehalfOf);
        return 1;
    }

    function supply(
        address caller,
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        emit Supply(caller, asset, amount, onBehalfOf, referralCode);
    }

    function getReserveData(address asset) external view returns (MokeReserveData memory) {
        return MokeReserveData(asset);
    }
}
