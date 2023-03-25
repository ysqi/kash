// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IDebitToken is IERC20 {
    function mint(address user, address onBehalfOf, uint256 amount, uint256 index) external;
    function burn(address from, uint256 amount, uint256 index) external;

    function scaledTotalSupply() external view returns (uint256);
}
