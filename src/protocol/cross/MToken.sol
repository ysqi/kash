// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/access/Ownable.sol";

contract MToken is Ownable, ERC20Permit {
    constructor(string memory name, string memory symbol, address miner)
        ERC20Permit(name)
        ERC20(name, symbol)
    {
        _transferOwnership(miner);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
