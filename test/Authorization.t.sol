// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VulnerableTreasury} from "../src/vulnerable/VulnerableTreasury.sol";
import {FixedTreasury} from "../src/fixed/FixedTreasury.sol";
import {PhishingRelay, ITreasury} from "./helpers/PhishingRelay.sol";

contract AuthorizationTest is Test {
    address internal owner = makeAddr("owner");
    address internal outsider = makeAddr("outsider");

    function testRelayDrainsTxOriginTreasury() public {
        VulnerableTreasury treasury = new VulnerableTreasury(owner);
        vm.deal(address(treasury), 5 ether);
        PhishingRelay relay = new PhishingRelay();

        // Owner initiates a transaction to the relay, which calls the treasury.
        vm.prank(owner, owner);
        relay.forwardSweep(ITreasury(address(treasury)));

        assertEq(address(treasury).balance, 0);
        assertEq(address(relay).balance, 5 ether);
    }

    function testRelayCannotDrainOnlyOwnerTreasury() public {
        FixedTreasury treasury = new FixedTreasury(owner);
        vm.deal(address(treasury), 5 ether);
        PhishingRelay relay = new PhishingRelay();

        vm.prank(owner, owner);
        vm.expectRevert();
        relay.forwardSweep(ITreasury(address(treasury)));

        assertEq(address(treasury).balance, 5 ether);
        assertEq(address(relay).balance, 0);
    }

    function testDirectOwnerCanSweepFixedTreasury() public {
        FixedTreasury treasury = new FixedTreasury(owner);
        vm.deal(address(treasury), 5 ether);

        vm.prank(owner);
        treasury.sweep(payable(outsider));

        assertEq(address(treasury).balance, 0);
        assertEq(outsider.balance, 5 ether);
    }
}
