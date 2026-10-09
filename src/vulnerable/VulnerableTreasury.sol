// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice INTENTIONALLY VULNERABLE: tx.origin lets a called contract act as the owner.
/// @dev Keep this contract inside local tests only. Never deploy it with real funds.
contract VulnerableTreasury {
    error LocalChainOnly();
    address public immutable owner;

    constructor(address owner_) {
        if (block.chainid != 31337) revert LocalChainOnly();
        require(owner_ != address(0), "zero owner");
        owner = owner_;
    }

    receive() external payable {}

    function sweep(address payable to) external {
        require(tx.origin == owner, "not owner");
        require(to != address(0), "zero recipient");
        (bool sent,) = to.call{value: address(this).balance}("");
        require(sent, "send failed");
    }
}
