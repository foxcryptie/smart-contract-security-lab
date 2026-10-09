// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VulnerableBank} from "../src/vulnerable/VulnerableBank.sol";
import {FixedBank} from "../src/fixed/FixedBank.sol";
import {ReentrancyProbe, IBank} from "./helpers/ReentrancyProbe.sol";

contract ReentrancyTest is Test {
    address internal depositor = makeAddr("depositor");

    function testProbeDrainsVulnerableBank() public {
        VulnerableBank bank = new VulnerableBank();
        vm.deal(depositor, 5 ether);
        vm.prank(depositor);
        bank.deposit{value: 5 ether}();

        ReentrancyProbe probe = new ReentrancyProbe(IBank(address(bank)));
        vm.deal(address(this), 1 ether);
        probe.run{value: 1 ether}();

        assertEq(address(bank).balance, 0);
        assertEq(address(probe).balance, 6 ether);
        assertGt(probe.callbacks(), 1);
        assertEq(bank.balances(depositor), 5 ether); // Liability remains, ETH is gone.
    }

    function testProbeCannotDrainFixedBank() public {
        FixedBank bank = new FixedBank();
        vm.deal(depositor, 5 ether);
        vm.prank(depositor);
        bank.deposit{value: 5 ether}();

        ReentrancyProbe probe = new ReentrancyProbe(IBank(address(bank)));
        vm.deal(address(this), 1 ether);
        probe.run{value: 1 ether}();

        assertEq(address(bank).balance, 5 ether);
        assertEq(address(probe).balance, 1 ether);
        assertEq(probe.callbacks(), 1);
        assertEq(bank.balances(depositor), 5 ether);
    }
}
