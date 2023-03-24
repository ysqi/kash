// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/IDebitToken.sol";
import "./lib/helpers/Errors.sol";
import "./lib/KashSpaceStorage.sol";
import "./lib/logic/SpaceLogic.sol";
import "./lib/KashConstants.sol";
import "./lib/upgradeable/KashUUPSUpgradeable.sol";
import "../libaryes/WadMath.sol";

import "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";

contract KashDebitToken is IDebitToken, ERC20Permit {
    using WadMath for uint256;

    uint8 private _decimals;

    mapping(address => uint256) private _userStates;
    address public pool;

    constructor(string memory _name, string memory _symbol, uint8 decimals_)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    //  借款/index= Scaled
    //  借款 = Scaled * index
    function mint(address user, address onBehalfOf, uint256 amount, uint256 index)
        external
        onlyPool
    {
        uint256 mints = amount.wadDiv(index);
        // TODO: check zero
        _userStates[onBehalfOf] = index;
        _mint(onBehalfOf, mints);
    }

    function burn(address from, uint256 amount, uint256 index) external onlyPool {
        uint256 amountScaled = amount.wadDiv(index);
        _burn(from, amountScaled);
    }

    function scaledTotalSupply() external view returns (uint256) {
        return super.totalSupply();
    }

    // TODO: disable transfer debt.

    function setPool(address p) external {
        pool = p; // TODO: check admin
    }

    modifier onlyPool() {
        if (pool != msg.sender) revert Errors.NO_PERMISSION();
        _;
    }
}
