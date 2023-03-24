// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./KashDataTypes.sol";

contract KashSpaceStorage {
    // Active reserves on protocol.
    uint16 internal _reserveCount;

    // List of asset as map. (reserveId => asset)
    mapping(uint16 => address) internal _reserveList;

    // Map of reserves and their data (assetAddress => reserve)
    mapping(address => ReserveData) internal _reserves;

    mapping(address => ReserveConfigurationMap) internal _reserveConfigs;
    // Map of the configuration of the user across all the reserves (userAddress => config)
    mapping(address => UserConfigurationMap) internal _userConfigs;

    /**
     * The balance of asset on all chains.
     * e.g query the balance of WETH on ethereum:
     *     balance= liquidityShadow[chainId][asset]
     */
    mapping(uint256 => mapping(address => uint256)) public liquidityShadow;

    address public master;
}
