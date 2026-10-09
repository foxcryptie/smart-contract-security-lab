# Findings and remediations

These are controlled demonstrations in local Foundry tests. The impacts below describe the lab setup and must not be read as findings against a live project.

## 1. Reentrancy during ETH withdrawal

**Root cause:** [`VulnerableBank.withdraw()`](src/vulnerable/VulnerableBank.sol) calls the recipient while its recorded balance is still positive. The recipient's callback can enter `withdraw()` again and receive the same balance repeatedly.

**Demonstrated impact:** In `testProbeDrainsVulnerableBank`, a test depositor supplies 5 ETH and the probe supplies 1 ETH. The probe receives 6 ETH while the bank still records the depositor's 5 ETH liability. This is a local exploit proof, not a live theft.

**Remediation:** [`FixedBank`](src/fixed/FixedBank.sol) sets the caller's balance to zero before the external call and adds `ReentrancyGuard`. A failed send reverts the entire transaction, including the state update. The paired test confirms the probe receives only its own 1 ETH.

**Further review:** A real bank would need a wider asset-accounting model, safe admin operations, and tests across every external-call path.

## 2. `tx.origin` authorization

**Root cause:** [`VulnerableTreasury.sweep()`](src/vulnerable/VulnerableTreasury.sol) accepts any caller if the original transaction sender is the owner. The owner can be induced to call a relay that then calls `sweep()` with the relay as the recipient.

**Demonstrated impact:** `testRelayDrainsTxOriginTreasury` shows a local relay receiving the treasury's 5 ETH. The owner initiates the relay call, but does not call the treasury directly.

**Remediation:** [`FixedTreasury`](src/fixed/FixedTreasury.sol) uses `Ownable` and `onlyOwner`, which checks the direct caller. The relay fails while an owner call succeeds.

**Further review:** Production custody also needs an ownership and key-management plan, event logging, and an explicit policy for contract owners or multisigs.

## 3. Signed claim replay

**Root cause:** [`VulnerableClaim`](src/vulnerable/VulnerableClaim.sol) signs only `(recipient, amount)`. The contract never marks an authorization as used, so a caller can submit the same signature again. The message also lacks a contract address, chain ID, and expiry.

**Demonstrated impact:** `testSameSignaturePaysTwiceInVulnerableClaim` spends 2 ETH using one signature intended for a 1 ETH claim.

**Remediation:** [`FixedClaim`](src/fixed/FixedClaim.sol) uses EIP-712 typed data bound to the contract and chain, a per-recipient nonce, and a deadline. It advances the nonce before transferring ETH. Tests cover repeated use, another contract, another chain ID, and expiration.

**Further review:** A real payout system would need signer rotation, cancellation, funding controls, monitoring, and a defined claim authorization process. Its off-chain signer must sign the exact EIP-712 typed data used by the contract.

## Interpretation

All three vulnerabilities are deliberate. The local-chain constructor checks reduce accidental deployment but do not make the contracts safe on any network, including one with chain ID 31337. Passing CI means that the tests observed the stated behavior; it is not a security certification.
