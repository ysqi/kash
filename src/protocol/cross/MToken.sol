// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";

contract MToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, address door) ERC20(name, symbol) {
        _transferOwnership(door);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
