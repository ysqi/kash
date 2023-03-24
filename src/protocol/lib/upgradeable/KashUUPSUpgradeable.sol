//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";

abstract contract KashUUPSUpgradeable is OwnableUpgradeable, UUPSUpgradeable {
    /**
     * @dev oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev no constructor in upgradable contracts. Instead we have initializers
     */
    function _init() internal {
        __Ownable_init();
    }

    /**
     * @dev required by the OZ UUPS module
     */
    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}
