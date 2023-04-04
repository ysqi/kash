// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IMintable {
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

contract Minter {
    function mint(address token, address to, uint256 amount) external {
        IMintable(token).mint(amount);

        if (to != address(0)) {
            IMintable(token).transfer(to, amount);
        }
    }

    function call(address token, bytes calldata data) external {
        (bool success,) = token.call(data);
        require(success, "Minter: call failed");
    }
}
