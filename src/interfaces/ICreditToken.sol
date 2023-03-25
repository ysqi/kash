// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

import "./IScaledBalanceToken.sol";

interface ICreditToken is IERC20, IScaledBalanceToken, IERC20Permit {
    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The scaled amount being transferred
     * @param index The next liquidity index of the reserve
     */
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @notice Mints `amount` creditTokens to `user`
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted creditTokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address caller, address onBehalfOf, uint256 amount, uint256 index)
        external
        returns (bool);

    /**
     * @notice Burns creditTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the creditTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The next liquidity index of the reserve
     */
    function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index)
        external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param target The recipient of the underlying
     * @param amount The amount getting transferred
     */
    function transferUnderlyingTo(address target, uint256 amount) external;

    function handleRepayment(address caller, uint256 amount) external;

    /**
     * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}
