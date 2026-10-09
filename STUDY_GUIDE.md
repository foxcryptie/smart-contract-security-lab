# Study guide

Start with one case at a time. Run the named test, predict the balances and call sequence, then check the assertions.

## Reentrancy

1. Read `VulnerableBank.withdraw()` and mark the external call and balance update.
2. Run `forge test --match-test testProbeDrainsVulnerableBank -vvvv`.
3. Follow the `ReentrancyProbe.receive()` callback. Explain why the probe can withdraw while its bank balance is still 1 ETH.
4. Compare `FixedBank.withdraw()` and run `forge test --match-test testProbeCannotDrainFixedBank -vvvv`.
5. Explain why the fixed bank keeps the depositor's 5 ETH after the probe withdraws.

## Authorization

1. Compare `msg.sender` and `tx.origin` during the call from `PhishingRelay` to the treasury.
2. Run `forge test --match-test testRelayDrainsTxOriginTreasury -vvvv`.
3. Explain why `onlyOwner` blocks the same relay in `testRelayCannotDrainOnlyOwnerTreasury`.
4. Confirm the direct owner path still works in `testDirectOwnerCanSweepFixedTreasury`.

## Signature replay

1. List every field in the vulnerable signed message and identify what it omits.
2. Run `forge test --match-test testSameSignaturePaysTwiceInVulnerableClaim -vvvv`.
3. Inspect the fixed EIP-712 type hash, domain, nonce, and deadline.
4. Run `forge test --match-contract SignatureReplayTest -vv` and explain which field makes each rejected replay invalid.

## Review questions

- Why does a passing exploit test show that a contract is vulnerable rather than safe?
- Why is `block.chainid == 31337` a guard against mistakes rather than a security guarantee?
- What security properties are still untested in the fixed examples?

For the short write-up of each case, see [FINDINGS.md](FINDINGS.md). For source material, see the references in [README.md](README.md).
