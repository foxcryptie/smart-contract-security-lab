// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Requires the direct caller to be the owner.
contract FixedTreasury is Ownable {
    constructor(address owner_) Ownable(owner_) {}

    receive() external payable {}

    function sweep(address payable to) external onlyOwner {
        require(to != address(0), "zero recipient");
        (bool sent,) = to.call{value: address(this).balance}("");
        require(sent, "send failed");
    }
}
