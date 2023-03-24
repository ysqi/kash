// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

contract MockMos {
    constructor() { }

    struct CallData {
        bytes target;
        bytes callData;
        uint256 gasLimit;
        uint256 value;
    }

    event TransferOut(uint256 toChain, CallData callData);

    function transferOut(uint256 toChain, CallData memory callData)
        external
        payable
        returns (bool)
    {
        emit TransferOut(toChain, callData);
        return true;
    }
}
