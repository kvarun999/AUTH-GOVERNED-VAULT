## Security & Invariant Design
The system is built on three core security pillars:

1. **Separation of Concerns**: The `SecureVault` handles asset custody, while the `AuthorizationManager` handles logic. The Vault cannot move a single Wei without a successful external call to the manager.
2. **EIP-712 Structured Data**: Authorizations are not just raw hashes; they are structured messages bound to:
   - **Chain ID**: Prevents replay attacks on other forks/networks.
   - **Contract Address**: Ensures a signature for one vault cannot be used on another.
   - **Nonce**: Guarantees each signature is "Single Use Only."
3. **CEI Pattern**: The system follows the **Check-Effects-Interactions** pattern. Nonces are marked as used *before* any Ether is transferred, eliminating reentrancy risks.

## Verified Invariants
- Vault Balance >= 0 (Enforced by EVM math and state checks).
- Nonce Re-use = Revert (Enforced by `usedNonces` mapping).
- Invalid Signer = Revert (Enforced by `ECDSA.recover`).