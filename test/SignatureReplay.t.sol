// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VulnerableClaim} from "../src/vulnerable/VulnerableClaim.sol";
import {FixedClaim} from "../src/fixed/FixedClaim.sol";

contract SignatureReplayTest is Test {
    uint256 internal constant SIGNER_KEY = 0xA11CE;
    address internal signer;
    address payable internal recipient;

    function setUp() public {
        signer = vm.addr(SIGNER_KEY);
        recipient = payable(makeAddr("recipient"));
    }

    function _sign(bytes32 digest) internal returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_KEY, digest);
        return abi.encodePacked(r, s, v);
    }

    function testSameSignaturePaysTwiceInVulnerableClaim() public {
        VulnerableClaim payout = new VulnerableClaim(signer);
        vm.deal(address(payout), 2 ether);
        bytes memory signature = _sign(payout.hashClaim(recipient, 1 ether));

        payout.claim(recipient, 1 ether, signature);
        payout.claim(recipient, 1 ether, signature);

        assertEq(recipient.balance, 2 ether);
        assertEq(address(payout).balance, 0);
    }

    function testFixedClaimConsumesNonce() public {
        FixedClaim payout = new FixedClaim(signer);
        vm.deal(address(payout), 2 ether);
        uint256 deadline = block.timestamp + 1 days;
        bytes memory signature = _sign(payout.hashClaim(recipient, 1 ether, 0, deadline));

        payout.claim(recipient, 1 ether, deadline, signature);
        assertEq(payout.nonces(recipient), 1);
        vm.expectRevert(FixedClaim.InvalidSignature.selector);
        payout.claim(recipient, 1 ether, deadline, signature);

        assertEq(recipient.balance, 1 ether);
        assertEq(address(payout).balance, 1 ether);
    }

    function testFixedSignatureCannotBeUsedOnAnotherContract() public {
        FixedClaim first = new FixedClaim(signer);
        FixedClaim second = new FixedClaim(signer);
        vm.deal(address(second), 1 ether);
        uint256 deadline = block.timestamp + 1 days;
        bytes memory signature = _sign(first.hashClaim(recipient, 1 ether, 0, deadline));

        vm.expectRevert(FixedClaim.InvalidSignature.selector);
        second.claim(recipient, 1 ether, deadline, signature);
        assertEq(address(second).balance, 1 ether);
    }

    function testFixedSignatureCannotBeUsedOnAnotherChainId() public {
        FixedClaim payout = new FixedClaim(signer);
        vm.deal(address(payout), 1 ether);
        uint256 deadline = block.timestamp + 1 days;
        bytes memory signature = _sign(payout.hashClaim(recipient, 1 ether, 0, deadline));
        vm.chainId(block.chainid + 1);

        vm.expectRevert(FixedClaim.InvalidSignature.selector);
        payout.claim(recipient, 1 ether, deadline, signature);
        assertEq(address(payout).balance, 1 ether);
    }

    function testExpiredFixedClaimReverts() public {
        FixedClaim payout = new FixedClaim(signer);
        vm.deal(address(payout), 1 ether);
        uint256 deadline = block.timestamp + 1 days;
        bytes memory signature = _sign(payout.hashClaim(recipient, 1 ether, 0, deadline));
        vm.warp(deadline + 1);

        vm.expectRevert(FixedClaim.SignatureExpired.selector);
        payout.claim(recipient, 1 ether, deadline, signature);
        assertEq(address(payout).balance, 1 ether);
    }
}
