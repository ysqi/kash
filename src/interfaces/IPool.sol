// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "../protocol/lib/KashDataTypes.sol";
import "../protocol/lib/KashEnums.sol";

/**
 * @title IPool
 * @author KashSpace
 * @notice Defines the basic interface for an KashSpace Pool.
 */

interface IPool {
    /**
     * @dev Emitted on mintUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
     * @param amount The amount of supplied assets
     * @param referralCode The referral code used
     */
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on backUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param backer The address paying for the backing
     * @param amount The amount added as backing
     * @param fee The amount paid in fees
     */
    event BackUnbacked(
        address indexed reserve, address indexed backer, uint256 amount, uint256 fee
    );

    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     */
    event Withdraw(
        address indexed reserve, address indexed user, address indexed to, uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useATokens
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     */
    event SwapBorrowRateMode(
        address indexed reserve, address indexed user, InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param asset The address of the underlying asset of the reserve
     * @param totalDebt The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
     * @param user The address of the user
     * @param categoryId The category id
     */
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     */
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        external;

    function withdraw(address asset, uint256 amount, address onBehalfOf)
        external
        returns (uint256);

    function borrow(address asset, uint256 amount, address onBehalfOf) external;

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256);

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    // /**
    //  * @notice Updates the address of the interest rate strategy contract
    //  * @dev Only callable by the PoolConfigurator contract
    //  * @param asset The address of the underlying asset of the reserve
    //  * @param rateStrategyAddress The address of the interest rate strategy contract
    //  */
    // function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    //     external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(address asset, ReserveConfigurationMap calldata configuration)
        external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(address asset)
        external
        view
        returns (ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     */
    function getUserConfiguration(address user)
        external
        view
        returns (UserConfigurationMap memory);

    // /**
    //  * @notice Returns the normalized income of the reserve
    //  * @param asset The address of the underlying asset of the reserve
    //  * @return The reserve's normalized income
    //  */
    // function getReserveNormalizedIncome(address asset) external view returns (uint256);

    // /**
    //  * @notice Returns the normalized variable debt per unit of asset
    //  * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
    //  * "dynamic" variable index based on time, current stored index and virtual rate at the current
    //  * moment (approx. a borrower would get if opening a position). This means that is always used in
    //  * combination with variable debt supply/balances.
    //  * If using this function externally, consider that is possible to have an increasing normalized
    //  * variable debt that is not equivalent to how the variable debt index would be updated in storage
    //  * (e.g. only updates with non-zero variable debt supply)
    //  * @param asset The address of the underlying asset of the reserve
    //  * @return The reserve normalized variable debt
    //  */
    // function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(address asset) external view returns (ReserveData memory);

    // /**
    //  * @notice Validates and finalizes an aToken transfer
    //  * @dev Only callable by the overlying aToken of the `asset`
    //  * @param asset The address of the underlying asset of the aToken
    //  * @param from The user from which the aTokens are transferred
    //  * @param to The user receiving the aTokens
    //  * @param amount The amount being transferred/withdrawn
    //  * @param balanceFromBefore The aToken balance of the `from` user before the transfer
    //  * @param balanceToBefore The aToken balance of the `to` user before the transfer
    //  */
    // function finalizeTransfer(
    //     address asset,
    //     address from,
    //     address to,
    //     uint256 amount,
    //     uint256 balanceFromBefore,
    //     uint256 balanceToBefore
    // ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    function getReserveRealLiquidityIndex(address asset) external view returns (uint256);
    function getReserveRealBorrowIndex(address asset) external view returns (uint256);

    // /**
    //  * @notice Allows a user to use the protocol in eMode
    //  * @param categoryId The id of the category
    //  */
    // function setUserEMode(uint8 categoryId) external;

    // /**
    //  * @notice Returns the eMode the user is using
    //  * @param user The address of the user
    //  * @return The eMode id
    //  */
    // function getUserEMode(address user) external view returns (uint256);

    // /**
    //  * @notice Resets the isolation mode total debt of the given asset to zero
    //  * @dev It requires the given asset has zero debt ceiling
    //  * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
    //  */
    // function resetIsolationModeTotalDebt(address asset) external;

    // /**
    //  * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
    //  * @return The percentage of available liquidity to borrow, expressed in bps
    //  */
    // function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    // /**
    //  * @notice Returns the total fee on flash loans
    //  * @return The total fee on flashloans
    //  */
    // function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
     * @return The bridge fee sent to the protocol treasury
     */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    // /**
    //  * @notice Returns the part of the flashloan fees sent to protocol
    //  * @return The flashloan fee sent to the protocol treasury
    //  */
    // function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    // /**
    //  * @notice Returns the maximum number of reserves supported to be listed in this Pool
    //  * @return The maximum number of reserves supported
    //  */
    // function MAX_NUMBER_RESERVES() external view returns (uint16);

    // /**
    //  * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
    //  * @param assets The list of reserves for which the minting needs to be executed
    //  */
    // function mintToTreasury(address[] calldata assets) external;

    // /**
    //  * @notice Rescue and transfer tokens locked in this contract
    //  * @param token The address of the token
    //  * @param to The address of the recipient
    //  * @param amount The amount of token to transfer
    //  */
    // function rescueTokens(address token, address to, uint256 amount) external;
}
