// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/ICreditToken.sol";
import "./lib/helpers/Errors.sol";
import "./lib/KashSpaceStorage.sol";
import "./lib/logic/SpaceLogic.sol";
import "./lib/KashConstants.sol";
import "../libaryes/WadMath.sol";
import "./lib/upgradeable/KashUUPSUpgradeable.sol";

import "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract KashCreditToken is ICreditToken, ERC20Permit {
    using WadMath for uint256;
    using SafeERC20 for IERC20;

    address private _underlyingAsset;
    uint8 private _decimals;

    mapping(address => uint256) private _userStates;
    address public pool;

    constructor(address asset, string memory _name, string memory _symbol, uint8 decimals_)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        _decimals = decimals_;
        _underlyingAsset = asset;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function UNDERLYING_ASSET_ADDRESS() external view returns (address) {
        return _underlyingAsset;
    }

    function mint(address user, address onBehalfOf, uint256 amount, uint256 index)
        external
        onlyPool
        returns (bool preZero)
    {
        preZero = balanceOf(onBehalfOf) == 0;

        IERC20(_underlyingAsset).safeTransferFrom(user, address(this), amount);
        uint256 mints = amount.wadDiv(index);
        // TODO: check zero
        _userStates[onBehalfOf] = index;
        _mint(onBehalfOf, mints);
    }

    function burn(address from, address onBehalfOf, uint256 amount, uint256 index)
        external
        onlyPool
    {
        uint256 amountScaled = amount.wadDiv(index);
        _burn(from, amountScaled);
        IERC20(_underlyingAsset).safeTransfer(onBehalfOf, amount);
    }

    function transferUnderlyingTo(address target, uint256 amount) external onlyPool {
        IERC20(_underlyingAsset).safeTransfer(target, amount);
    }

    function scaledTotalSupply() external view returns (uint256) {
        return super.totalSupply();
    }

    function scaledBalanceOf(address user) external pure returns (uint256) {
        revert("NO");
    }

    // TODO: safe check before transfer credit.

    function setPool(address p) external {
        pool = p; // TODO: check admin
    }

    modifier onlyPool() {
        if (pool != msg.sender) revert Errors.NO_PERMISSION();
        _;
    }
}
