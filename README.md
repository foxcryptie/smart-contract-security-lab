# Smart Contract Security Lab

[![Foundry CI](https://github.com/foxcryptie/smart-contract-security-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/foxcryptie/smart-contract-security-lab/actions/workflows/ci.yml)

Three small Foundry cases. Each starts with a contract that has one deliberate flaw, then uses a test to show the failure and a second contract to show a specific fix. The tests passing means the demonstrations behaved as expected; it does not mean the vulnerable code is safe.

| Case | What the test shows | Paired fix |
| --- | --- | --- |
| [Reentrancy](test/Reentrancy.t.sol) | A probe reenters `withdraw()` before its balance is cleared and drains the test bank. | Clear balance before sending ETH and guard reentry. |
| [Authorization](test/Authorization.t.sol) | A relay passes a `tx.origin` owner check even though the owner did not call the treasury directly. | Authorize `msg.sender` with `onlyOwner`. |
| [Signature replay](test/SignatureReplay.t.sol) | The same signed claim pays twice. | Bind the claim to a contract and chain with EIP-712, then consume a nonce and enforce a deadline. |

The flawed contracts are under [`src/vulnerable`](src/vulnerable); the paired versions are under [`src/fixed`](src/fixed). [`FINDINGS.md`](FINDINGS.md) gives the call sequence and balances for each case. [`STUDY_GUIDE.md`](STUDY_GUIDE.md) has commands for stepping through individual tests.

## Run locally

Install [Foundry](https://book.getfoundry.sh/getting-started/installation) and Git, then fetch the pinned dependencies:

```bash
mkdir -p lib
git clone --depth 1 --branch v5.6.1 https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts
git clone --depth 1 --branch v1.17.0 https://github.com/foundry-rs/forge-std.git lib/forge-std
forge build
forge test -vv
```

For a first pass, run `forge test --match-contract ReentrancyTest -vvvv` and follow the external call in `VulnerableBank.withdraw()` and the callback in `ReentrancyProbe.receive()`.

The vulnerable constructors restrict deployment to chain ID `31337` to reduce accidents, but that number is not a security boundary. Everything here is for local study. The fixed contracts cover only the demonstrated flaw, have not been audited, and are not complete production components.
