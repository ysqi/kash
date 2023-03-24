// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IKashCrossDoor {
    /**
     * @notice Processing deposit requests from vault chains.
     * @param sideAsset is the hash value of sha3(chainId,assetAddress)
     * @param suppler is the suppler address.
     * @param amount is the amount of supply.
     * @param data is the other params.
     */
    function handleSupply(bytes32 sideAsset, bytes32 suppler, uint256 amount, bytes calldata data)
        external;

    /**
     * @notice Processing borrow requests from vault chains.
     * @param sideAsset is the hash value of sha3(chainId,assetAddress)
     * @param borrower is the borrower for this loan.
     * @param amount is the borrowing amount.
     * @param data is the other params.
     */
    function handleRepay(bytes32 sideAsset, bytes32 borrower, uint256 amount, bytes calldata data)
        external;

    /**
     * @notice Processing withdraw requests on MOS chain.
     * @param caller is the siger of this withdraw transaction.
     * @param chainId is target chianid.
     * @param asset is target asset.
     * @param receiver is the recipient of asset withdrawals.
     * @param amount is the amount of withdrawals.
     */
    function handleWithdraw(
        address caller,
        uint256 chainId,
        address asset,
        bytes32 receiver,
        uint256 amount
    ) external;

    /**
     * @notice Processing borrow requests on MOS chain.
     * @param caller is the siger of this withdraw transaction.
     * @param chainId is target chianid.
     * @param asset is target asset.
     * @param borrower is the borrower for this loan.
     * @param amount is the borrowing amount.
     */
    function handleBorrow(
        address caller,
        uint256 chainId,
        address asset,
        bytes32 borrower,
        uint256 amount
    ) external;
}
