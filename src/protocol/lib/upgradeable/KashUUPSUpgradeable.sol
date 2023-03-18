//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/proxy/utils/Initializable.sol";
import "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/access/Ownable.sol";

abstract contract KashUUPSUpgradeable is Ownable, Initializable, UUPSUpgradeable {
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
        _transferOwnership(msg.sender);
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
