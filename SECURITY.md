# Security Policy

## Supported Versions

This project is currently in active development. Security updates will be applied to the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of our smart contracts and infrastructure seriously. If you discover a security vulnerability, please follow these steps:

### 1. DO NOT Create a Public Issue

Please **do not** create a public GitHub issue for security vulnerabilities. This could put users at risk.

### 2. Report Privately

Send details about the vulnerability to:

- **Email**: security@example.com (replace with actual email)
- **Subject**: "[SECURITY] CCIP NFT Bridge Vulnerability Report"

### 3. Include in Your Report

To help us understand and address the issue quickly, please include:

- **Type of vulnerability**: (e.g., reentrancy, access control, oracle manipulation)
- **Location**: Contract name, function, and line numbers
- **Impact**: Potential consequences of the vulnerability
- **Reproduction**: Step-by-step instructions to reproduce
- **Proof of Concept**: Code or transaction examples
- **Suggested Fix**: If you have one (optional)

### Example Report

```
Subject: [SECURITY] CCIP NFT Bridge Vulnerability Report

Vulnerability Type: Access Control Bypass
Location: src/CCIPNFTBridge.sol, line 95
Severity: High

Description:
The sendNFT function does not properly validate ownership before burning
the NFT, allowing an attacker to burn NFTs they don't own if they have
approval.

Impact:
- Users can lose their NFTs without consent
- Bridge integrity is compromised
- Trust in the system is lost

Reproduction:
1. User A owns NFT with tokenId 1
2. User A approves User B for tokenId 1
3. User B calls sendNFT(destChain, userB, 1)
4. NFT is burned from User A but message sent to User B

Proof of Concept:
[Include code or transaction hash]

Suggested Fix:
Add ownership check in sendNFT:
require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
```

## Response Timeline

- **Acknowledgment**: Within 24-48 hours
- **Initial Assessment**: Within 1 week
- **Fix Implementation**: Depends on severity
  - Critical: 1-3 days
  - High: 1-2 weeks
  - Medium: 2-4 weeks
  - Low: Next release cycle

## Disclosure Policy

### Coordinated Disclosure

We follow a coordinated disclosure process:

1. **Private Reporting**: Researcher reports vulnerability privately
2. **Acknowledgment**: We acknowledge receipt within 48 hours
3. **Validation**: We validate and assess the vulnerability
4. **Fix Development**: We develop and test a fix
5. **Fix Deployment**: We deploy the fix to all networks
6. **Public Disclosure**: After fix is live, we jointly disclose:
   - Details of the vulnerability
   - Impact assessment
   - Fix explanation
   - Credit to the researcher (if desired)

### Disclosure Timeline

- **30 days**: Standard timeline from report to public disclosure
- **Extended**: For complex issues requiring more time
- **Shorter**: For actively exploited vulnerabilities

## Bug Bounty Program

### Scope

The following contracts are in scope for bug bounties:

- `src/CrossChainNFT.sol`
- `src/CCIPNFTBridge.sol`

### Rewards

Rewards are based on severity and impact:

| Severity | Description | Reward |
|----------|-------------|--------|
| Critical | Loss of funds, unauthorized minting, bridge compromise | $5,000 - $10,000 |
| High | Access control bypass, DOS, data corruption | $2,000 - $5,000 |
| Medium | Logic errors, information disclosure | $500 - $2,000 |
| Low | Minor issues, best practice violations | $100 - $500 |

**Note**: This is a testnet project. Actual rewards may be adjusted based on available budget.

### Eligibility

To be eligible for a reward:

- ✅ Follow responsible disclosure
- ✅ Provide clear reproduction steps
- ✅ Submit before public disclosure
- ✅ Be the first reporter of the issue
- ✅ Not exploit the vulnerability beyond PoC

Not eligible:

- ❌ Already known issues
- ❌ Out-of-scope vulnerabilities
- ❌ Public disclosures before fix
- ❌ Social engineering attacks
- ❌ Third-party dependencies (unless integration issue)

## Known Issues & Limitations

### Current Limitations

1. **Testnet Only**: Currently deployed only to testnets
2. **No Proxy Pattern**: Contracts are not upgradeable
3. **Gas Limits**: Fixed gas limits in cross-chain calls
4. **Rate Limiting**: No rate limiting mechanism
5. **Emergency Pause**: No circuit breaker implemented

### Future Improvements

- [ ] Implement upgradeable proxy pattern
- [ ] Add emergency pause functionality
- [ ] Implement rate limiting
- [ ] Add multi-sig control for admin functions
- [ ] Conduct professional security audit

## Security Best Practices

### For Users

1. **Verify Contract Addresses**: Always double-check contract addresses
2. **Use Hardware Wallets**: For significant value transfers
3. **Check Transaction Details**: Before signing any transaction
4. **Monitor CCIP Explorer**: Track your cross-chain messages
5. **Be Patient**: Wait for confirmations before assuming completion

### For Developers

1. **Access Control**: Always validate permissions
2. **Input Validation**: Sanitize all inputs
3. **Reentrancy Guards**: Use for external calls
4. **Integer Overflow**: Use Solidity 0.8+ or SafeMath
5. **Testing**: Comprehensive test coverage
6. **Auditing**: Get code reviewed by peers

## Audit Reports

### Planned Audits

We plan to conduct security audits before mainnet deployment:

- [ ] Internal security review
- [ ] Peer review by experienced developers
- [ ] Professional audit by reputable firm
- [ ] Bug bounty program

Audit reports will be published here once completed.

## Security Checklist

When contributing code, ensure:

- [ ] No hardcoded private keys or secrets
- [ ] Access control on all admin functions
- [ ] Input validation on all external/public functions  
- [ ] Reentrancy guards where needed
- [ ] No unchecked external calls
- [ ] Events emitted for important state changes
- [ ] SafeMath or Solidity 0.8+ for arithmetic
- [ ] Tests for security-critical functions
- [ ] NatSpec documentation for complex logic
- [ ] Gas limits considered for cross-chain calls

## Additional Resources

### Security Tools

- [Slither](https://github.com/crytic/slither) - Static analyzer
- [Mythril](https://github.com/ConsenSys/mythril) - Security analysis
- [Echidna](https://github.com/crytic/echidna) - Fuzzing
- [Foundry](https://github.com/foundry-rs/foundry) - Testing framework

### Security References

- [Chainlink CCIP Security](https://docs.chain.link/ccip/security)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [OpenZeppelin Security](https://docs.openzeppelin.com/contracts/4.x/security)
- [Solidity Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)

## Contact

For security-related questions or concerns:

- **Email**: security@example.com
- **Discord**: [Invite Link]
- **GitHub**: Open a private security advisory

---

**Last Updated**: February 22, 2026  
**Next Review**: March 22, 2026
