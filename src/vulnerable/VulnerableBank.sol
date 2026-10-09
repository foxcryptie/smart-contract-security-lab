// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice INTENTIONALLY VULNERABLE: external ETH transfer precedes the balance update.
/// @dev Keep this contract inside local tests only. Never deploy it with real funds.
contract VulnerableBank {
    error LocalChainOnly();
    mapping(address account => uint256) public balances;

    constructor() {
        if (block.chainid != 31337) revert LocalChainOnly();
    }

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "no balance");

        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "send failed");

        // A receiver can call withdraw again before this line executes.
        balances[msg.sender] = 0;
    }
}
