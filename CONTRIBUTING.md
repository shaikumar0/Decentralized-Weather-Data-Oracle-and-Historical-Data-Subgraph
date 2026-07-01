# Contributing to CCIP NFT Bridge

Thank you for your interest in contributing to the CCIP NFT Bridge project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Testing Guidelines](#testing-guidelines)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of experience level, gender identity, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, or nationality.

### Our Standards

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

1. Install required tools:
   - [Foundry](https://book.getfoundry.sh/getting-started/installation)
   - [Node.js](https://nodejs.org/) v18+
   - [Git](https://git-scm.com/)
   - [Docker](https://www.docker.com/get-started) (optional)

2. Fork the repository on GitHub

3. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ccip-nft-bridge.git
   cd ccip-nft-bridge
   ```

4. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/ccip-nft-bridge.git
   ```

### Initial Setup

```bash
# Install dependencies
forge install
npm install

# Copy environment template
cp .env.example .env

# Compile contracts
forge build

# Run tests
forge test
```

## Development Workflow

### 1. Create a Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or modifications

### 2. Make Changes

- Write clean, readable code
- Follow existing code style
- Add tests for new functionality
- Update documentation as needed
- Keep commits small and focused

### 3. Test Your Changes

```bash
# Run unit tests
forge test -vv

# Run specific test
forge test --match-test testFunctionName

# Check gas usage
forge test --gas-report

# Run with coverage
forge coverage
```

### 4. Commit Changes

```bash
# Stage your changes
git add .

# Commit with descriptive message
git commit -m "feat: add feature description"
```

Commit message conventions:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test additions or changes
- `chore:` - Maintenance tasks

### 5. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Testing Guidelines

### Writing Tests

1. **Unit Tests**: Test individual functions in isolation
   ```solidity
   function testMintFromBridge() public {
       vm.prank(bridge);
       nft.mint(user, 1, "ipfs://test");
       assertEq(nft.ownerOf(1), user);
   }
   ```

2. **Integration Tests**: Test interactions between contracts
   ```solidity
   function testCrossChainTransfer() public {
       // Setup, execute, verify
   }
   ```

3. **Edge Cases**: Test boundary conditions and error cases
   ```solidity
   function testMintFailsForNonBridge() public {
       vm.prank(user);
       vm.expectRevert("Caller is not the bridge");
       nft.mint(user, 1, "ipfs://test");
   }
   ```

### Test Coverage

- Aim for >80% code coverage
- Test all public/external functions
- Test access control mechanisms
- Test edge cases and error conditions
- Test event emissions

## Coding Standards

### Solidity Style Guide

Follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Interface} from "./Interface.sol";

/**
 * @title ContractName
 * @notice Brief description
 * @dev Detailed technical notes
 */
contract ContractName {
    // Type declarations
    using SafeMath for uint256;
    
    // State variables
    uint256 public constant MAX_SUPPLY = 10000;
    address public owner;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // Constructor
    constructor(address _owner) {
        owner = _owner;
    }
    
    // External functions
    function transfer(address to, uint256 amount) external {
        // Implementation
    }
    
    // Public functions
    function balanceOf(address account) public view returns (uint256) {
        // Implementation
    }
    
    // Internal functions
    function _transfer(address from, address to, uint256 amount) internal {
        // Implementation
    }
    
    // Private functions
    function _validate(address account) private view returns (bool) {
        // Implementation
    }
}
```

### JavaScript/Node.js Style

```javascript
// Use const/let, not var
const fs = require('fs');
let counter = 0;

// Use arrow functions
const add = (a, b) => a + b;

// Use async/await
async function fetchData() {
  const response = await fetch(url);
  return response.json();
}

// Error handling
try {
  const result = await riskyOperation();
} catch (error) {
  console.error('Operation failed:', error.message);
}

// Descriptive names
const userAddress = '0x...';
const bridgeContract = new ethers.Contract(...);
```

### Documentation

1. **Smart Contracts**: Use NatSpec comments
   ```solidity
   /**
    * @notice Mints a new NFT to the specified address
    * @dev Only callable by the bridge contract
    * @param to The address to mint to
    * @param tokenId The ID of the token to mint
    * @param tokenURI The metadata URI for the token
    */
   function mint(address to, uint256 tokenId, string memory tokenURI) external onlyBridge {
       // Implementation
   }
   ```

2. **JavaScript**: Use JSDoc comments
   ```javascript
   /**
    * Transfers an NFT across chains
    * @param {number} tokenId - The token ID to transfer
    * @param {string} fromChain - Source chain name
    * @param {string} toChain - Destination chain name
    * @param {string} receiver - Receiver address
    * @returns {Promise<Object>} Transfer record
    */
   async function transferNFT(tokenId, fromChain, toChain, receiver) {
       // Implementation
   }
   ```

## Pull Request Process

### Before Submitting

- [ ] Tests pass locally (`forge test`)
- [ ] Code is formatted (`forge fmt`)
- [ ] No linter warnings
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] Branch is up to date with main

### PR Description Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
Describe how you tested your changes

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Follows project coding standards
```

### Review Process

1. At least one maintainer must review
2. All tests must pass
3. No merge conflicts
4. Follows coding standards
5. Documentation is adequate

### After Approval

- Squash commits if needed
- Ensure commit message is clear
- Merge using "Squash and merge" or "Rebase and merge"

## Reporting Bugs

### Before Reporting

1. Check existing issues
2. Search closed issues
3. Verify it's reproducible
4. Gather relevant information

### Bug Report Template

```markdown
## Bug Description
Clear and concise description of the bug

## To Reproduce
Steps to reproduce:
1. Deploy contracts
2. Execute function X
3. See error

## Expected Behavior
What you expected to happen

## Actual Behavior
What actually happened

## Environment
- OS: [e.g., Ubuntu 22.04]
- Foundry version: [e.g., 0.2.0]
- Node version: [e.g., 18.0.0]
- Network: [e.g., Avalanche Fuji]

## Additional Context
- Error messages
- Transaction hashes
- Screenshots
- Logs
```

## Feature Requests

### Feature Request Template

```markdown
## Feature Description
Clear and concise description of the feature

## Problem Statement
What problem does this solve?

## Proposed Solution
How should this work?

## Alternatives Considered
What other solutions did you consider?

## Additional Context
Any other relevant information
```

## Development Tips

### Gas Optimization

```solidity
// Use immutable for constants set in constructor
address public immutable router;

// Pack storage variables
struct User {
    address wallet;      // 20 bytes
    uint96 balance;      // 12 bytes (fits in same slot)
}

// Use custom errors (cheaper than strings)
error Unauthorized();
if (msg.sender != owner) revert Unauthorized();

// Cache storage reads
uint256 _supply = totalSupply;  // Read once
_supply += 1;
totalSupply = _supply;           // Write once
```

### Security Best Practices

```solidity
// Use OpenZeppelin contracts
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Check-Effects-Interactions pattern
function withdraw(uint256 amount) external nonReentrant {
    // Checks
    require(balance[msg.sender] >= amount, "Insufficient balance");
    
    // Effects
    balance[msg.sender] -= amount;
    
    // Interactions
    payable(msg.sender).transfer(amount);
}

// Use SafeERC20 for token transfers
using SafeERC20 for IERC20;
token.safeTransfer(to, amount);
```

### Debugging Tips

```bash
# Verbose test output
forge test -vvvv

# Debug specific function
forge test --debug testFunctionName

# Trace transaction
cast run TX_HASH --rpc-url $RPC_URL

# Decode transaction input
cast 4byte-decode DATA
```

## Questions?

- Open a GitHub Discussion
- Join our Discord
- Check existing documentation
- Ask in Pull Request comments

## License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.

---

Thank you for contributing! 🎉
