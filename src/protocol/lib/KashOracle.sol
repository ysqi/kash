// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/access/Ownable.sol";
import "../../interfaces/IPriceOracle.sol";
import "./helpers/Errors.sol";

contract KashOracle is IPriceOracle, Ownable {
    event PriceChanged(address indexed token, uint256 oldPrice, uint256 newPrice);

    mapping(address => Underlying) public prices;
    mapping(address => bool) public feeders;

    struct Underlying {
        uint256 lastUpdate;
        uint256 lastPriceMan;
    }

    constructor() {
        feeders[msg.sender] = true;
    }

    function getLastPrice(address token)
        external
        view
        override
        returns (uint256 updateAt, uint256 price)
    {
        Underlying storage info = prices[token];
        updateAt = info.lastUpdate;
        price = info.lastPriceMan;
    }

    function _setPrice(address token, uint256 priceMan) private {
        Underlying storage info = prices[token];
        if (priceMan == 0) revert Errors.INVALID_PRICE();
        uint256 old = info.lastPriceMan;
        info.lastUpdate = block.timestamp;
        info.lastPriceMan = priceMan;
        emit PriceChanged(token, old, priceMan);
    }

    function setPrice(address token, uint256 priceMan) external onlyFeeder {
        _setPrice(token, priceMan);
    }

    function batchSetPrice(address[] calldata tokens, uint256[] calldata priceMans)
        external
        onlyFeeder
    {
        require(tokens.length == priceMans.length, "ORACLE_INVALID_ARRAY");
        uint256 len = tokens.length;
        // ignore length check
        for (uint256 i = 0; i < len; i++) {
            _setPrice(tokens[i], priceMans[i]);
        }
    }

    function approveFeeder(address feeder) external onlyOwner {
        feeders[feeder] = true;
    }

    function removeFeeder(address feeder) external onlyOwner {
        delete feeders[feeder];
    }

    modifier onlyFeeder() {
        if (!feeders[msg.sender]) revert Errors.NO_PERMISSION();
        _;
    }
}
