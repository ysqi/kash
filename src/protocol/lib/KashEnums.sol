// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

enum MarketStatus {
    Unknown,
    Opened,
    Stopped
}

enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
}
