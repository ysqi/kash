// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library Errors {
    error NOT_CONTRACT(); // the address is not a smart contract.
    error ASSET_EXIST_RESERVE(); //the reserve of the asset is exist,you can't repeat set;
    error RESERVE_NOT_FOUND(); // can't find the reserve by asset.
    error NO_PERMISSION();
    error ILLEGAL_SIGNATURE();
    error EXPIRED_DEADLINE();
    error EMPTY_ADDRESS();
    error INVALID_PRICE();
    error REPEAT_CROSS_MSG();
    error MISSING_CHAINTOKENMAPPING();
    error INSUFFICIENT_VAULT_FUNDS();
}
