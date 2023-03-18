// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library Errors {
    error NOT_CONTRACT(); // the address is not a smart contract.
    error ASSET_EXIST_RESERVE(); //the reserve of the asset is exist,you can't repeat set;
}
