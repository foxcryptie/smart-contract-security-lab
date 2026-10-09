// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Updates the balance before sending ETH and guards the withdrawal entry point.
contract FixedBank is ReentrancyGuard {
    mapping(address account => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "no balance");

        balances[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "send failed");
    }
}
