# Smart Contract Security Lab

[![Foundry CI](https://github.com/foxcryptie/smart-contract-security-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/foxcryptie/smart-contract-security-lab/actions/workflows/ci.yml)

Three deliberately vulnerable Solidity examples, each paired with a corrected implementation and a Foundry test that demonstrates both behaviors. This is an educational reference for reviewing EVM authorization, external calls, and signed claims.

**Do not deploy the vulnerable contracts or use any of these contracts to hold real funds.** The vulnerable constructors allow deployment only when `block.chainid == 31337` to discourage accidental use; a chain ID check is not a security boundary, and anyone can create a network with that ID. The corrected contracts are learning examples, not audited production components.

## Cases

| Case | Vulnerable behavior | Corrected behavior | Proof |
| --- | --- | --- | --- |
| Reentrancy | `withdraw()` sends ETH before clearing the caller's balance. | Clears the balance before sending and uses `ReentrancyGuard`. | [`test/Reentrancy.t.sol`](test/Reentrancy.t.sol) |
| Authorization | `sweep()` trusts `tx.origin`, allowing a relay called by the owner to drain the treasury. | Uses `Ownable` to authorize the direct caller. | [`test/Authorization.t.sol`](test/Authorization.t.sol) |
| Signature replay | A signed claim contains no nonce, contract, chain, or deadline and can be paid repeatedly. | Uses EIP-712 domain separation, per-recipient nonces, a deadline, and checks-effects-interactions. | [`test/SignatureReplay.t.sol`](test/SignatureReplay.t.sol) |

Each pair lives in [`src/vulnerable`](src/vulnerable) and [`src/fixed`](src/fixed). The exploit helpers live under [`test/helpers`](test/helpers), never in a deployment script. See [findings](FINDINGS.md) for the cause, impact, and limits of each demonstration, then use the [study guide](STUDY_GUIDE.md) to work through the tests.

## Run locally

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation) and Git. Dependencies are pinned to OpenZeppelin Contracts `v5.6.1` and forge-std `v1.17.0` in CI.

```sh
mkdir -p lib
git clone --depth 1 --branch v5.6.1 https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts
git clone --depth 1 --branch v1.17.0 https://github.com/foundry-rs/forge-std.git lib/forge-std
forge build
forge test -vv
```

The CI workflow runs `forge build` and `forge test -vv` on pushes and pull requests. The intended outcome is for **all tests to pass**: some tests prove the vulnerable behavior occurs, while others prove the corresponding fix rejects it. A green badge does not mean the vulnerable contracts are safe.

## Scope and limitations

- All attack demonstrations use local Foundry state and test ETH. No live addresses, private keys, or external targets are involved.
- The examples isolate one issue at a time. They do not model a complete protocol, external integrations, unusual ERC-20 behavior, upgradeability, governance, or all possible attacks.
- The signature example uses a hard-coded **test-only** key through Foundry's `vm.sign`; it is not a credential for a deployed service.
- No independent audit has been performed. Do not infer production safety from the passing tests.

## References

- [Solidity Security Considerations](https://docs.soliditylang.org/en/v0.8.24/security-considerations.html)
- [OpenZeppelin cryptography utilities](https://docs.openzeppelin.com/contracts/5.x/api/utils/cryptography)
- [OpenZeppelin access control](https://docs.openzeppelin.com/contracts/5.x/api/access)
- [OWASP Smart Contract Weakness Enumeration](https://scs.owasp.org/SCWE/)

MIT licensed. The repository is an educational security lab, not an audit report.
