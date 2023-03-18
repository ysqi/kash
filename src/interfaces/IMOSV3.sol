// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMOSV3 {
    enum chainType {
        NULL,
        EVM,
        NEAR
    }

    struct CallData {
        bytes target;
        bytes callData;
        uint256 gasLimit;
        uint256 value;
    }

    function transferOut(uint256 toChain, CallData memory callData)
        external
        payable
        returns (bool);

    event mapMessageOut(
        uint256 indexed fromChain, uint256 indexed toChain, bytes32 orderId, bytes callData
    );

    event mapMessageIn(
        uint256 indexed fromChain, uint256 indexed toChain, bytes32 orderId, bool executeTag
    );
}
