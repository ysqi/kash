// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@openzeppelin/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private s_decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        ERC20(_name, _symbol)
    {
        s_decimals = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(uint256 value) public {
        _mint(msg.sender, value);
    }

    function mint(address to, uint256 value) public {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public {
        _burn(from, value);
    }
}
