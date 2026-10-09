// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice One-time ETH claims signed for this contract and chain.
/// @dev Demonstrates replay controls; it is not an audited payout system.
contract FixedClaim is EIP712, ReentrancyGuard {
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address recipient,uint256 amount,uint256 nonce,uint256 deadline)");

    address public immutable trustedSigner;
    mapping(address recipient => uint256) public nonces;

    error ZeroSigner();
    error InvalidClaim();
    error SignatureExpired();
    error InvalidSignature();
    error TransferFailed();

    constructor(address signer_) EIP712("SecurityLabClaim", "1") {
        if (signer_ == address(0)) revert ZeroSigner();
        trustedSigner = signer_;
    }

    receive() external payable {}

    function hashClaim(address recipient, uint256 amount, uint256 nonce, uint256 deadline)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(CLAIM_TYPEHASH, recipient, amount, nonce, deadline)));
    }

    function claim(address payable recipient, uint256 amount, uint256 deadline, bytes calldata signature)
        external
        nonReentrant
    {
        if (recipient == address(0) || amount == 0) revert InvalidClaim();
        if (block.timestamp > deadline) revert SignatureExpired();

        uint256 nonce = nonces[recipient];
        if (ECDSA.recover(hashClaim(recipient, amount, nonce, deadline), signature) != trustedSigner) {
            revert InvalidSignature();
        }

        nonces[recipient] = nonce + 1;
        (bool sent,) = recipient.call{value: amount}("");
        if (!sent) revert TransferFailed();
    }
}
