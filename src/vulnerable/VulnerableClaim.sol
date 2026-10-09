// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @notice INTENTIONALLY VULNERABLE: one authorization can be reused many times.
/// @dev Keep this contract inside local tests only. Never deploy it with real funds.
contract VulnerableClaim {
    error LocalChainOnly();
    address public immutable trustedSigner;

    constructor(address signer_) {
        if (block.chainid != 31337) revert LocalChainOnly();
        require(signer_ != address(0), "zero signer");
        trustedSigner = signer_;
    }

    receive() external payable {}

    function hashClaim(address recipient, uint256 amount) public pure returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(recipient, amount)));
    }

    function claim(address payable recipient, uint256 amount, bytes calldata signature) external {
        require(recipient != address(0) && amount > 0, "bad claim");
        require(ECDSA.recover(hashClaim(recipient, amount), signature) == trustedSigner, "bad signature");
        // No nonce, used-claim record, contract address, chain ID, or expiry.
        (bool sent,) = recipient.call{value: amount}("");
        require(sent, "send failed");
    }
}
