// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor() ERC20("USDT", "USDT") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}
