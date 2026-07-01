# Chainlink CCIP Cross-Chain NFT Bridge

A production-ready cross-chain NFT bridge using Chainlink's Cross-Chain Interoperability Protocol (CCIP). This project implements a secure burn-and-mint mechanism to transfer NFTs between Avalanche Fuji and Arbitrum Sepolia testnets while preserving metadata.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Usage](#usage)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Overview

This project demonstrates how to build a cross-chain NFT bridge using Chainlink CCIP. When a user transfers an NFT from one chain to another:

1. **Burn**: The NFT is burned on the source chain
2. **Message**: CCIP sends a message containing the NFT metadata
3. **Mint**: The NFT is minted on the destination chain with preserved metadata

This ensures the total supply remains constant across all chains, preventing duplicate NFTs.

## Features

- ✅ **ERC-721 NFT Contract** with access-controlled minting
- ✅ **CCIP Bridge Contract** for cross-chain messaging
- ✅ **Burn-and-Mint Mechanism** to maintain supply integrity
- ✅ **Metadata Preservation** across chains
- ✅ **CLI Tool** for easy NFT transfers
- ✅ **Docker Support** for containerized deployment
- ✅ **Comprehensive Logging** and transfer tracking
- ✅ **Idempotent Operations** to prevent duplicate mints
- ✅ **Cost Estimation** for LINK fees

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Avalanche Fuji                         │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  CrossChainNFT   │◄────────│  CCIPNFTBridge   │         │
│  │   (ERC-721)      │         │                  │         │
│  └──────────────────┘         └────────┬─────────┘         │
│         Burn NFT                       │                    │
└────────────────────────────────────────┼────────────────────┘
                                         │
                                   CCIP Message
                                (tokenId + URI)
                                         │
┌────────────────────────────────────────▼────────────────────┐
│                   Arbitrum Sepolia                          │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  CrossChainNFT   │◄────────│  CCIPNFTBridge   │         │
│  │   (ERC-721)      │         │                  │         │
│  └──────────────────┘         └──────────────────┘         │
│         Mint NFT                                            │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before you begin, ensure you have the following installed:

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)
- [Node.js](https://nodejs.org/) v18 or higher
- [Docker](https://www.docker.com/get-started) and Docker Compose
- [Git](https://git-scm.com/)

You'll also need:

- Testnet funds:
  - AVAX on Fuji: [Avalanche Faucet](https://faucet.avax.network/)
  - ETH on Arbitrum Sepolia: [Arbitrum Faucet](https://faucet.quicknode.com/arbitrum/sepolia)
- LINK tokens:
  - [Chainlink Faucet](https://faucets.chain.link/)

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd "Chainlink CCIP Cross-Chain NFT Transfer with Metadata Preservation"
   ```

2. **Install Foundry dependencies**:
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   forge install smartcontractkit/ccip
   forge install smartcontractkit/chainlink-brownie-contracts
   ```

3. **Install Node.js dependencies**:
   ```bash
   npm install
   ```

4. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your private key and RPC URLs
   ```

## Configuration

### Environment Variables

Edit the `.env` file with your configuration:

```bash
# Your wallet private key (DO NOT COMMIT THIS!)
PRIVATE_KEY=your_private_key_here

# RPC endpoints
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc

# CCIP Router addresses (pre-configured)
CCIP_ROUTER_FUJI=0xF694E193200268f9a4868e4Aa017A0118C9a8177
CCIP_ROUTER_ARBITRUM_SEPOLIA=0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165

# LINK token addresses (pre-configured)
LINK_TOKEN_FUJI=0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
LINK_TOKEN_ARBITRUM_SEPOLIA=0xb1D4538B4571d411F07960EF2838Ce337FE1E80E
```

## Deployment

### Step 1: Compile Contracts

```bash
forge build
```

### Step 2: Deploy to Avalanche Fuji

```bash
NETWORK=fuji forge script script/Deploy.s.sol:Deploy --rpc-url $FUJI_RPC_URL --broadcast --verify
```

Copy the deployed addresses and update `deployment.json`:

```json
{
  "avalancheFuji": {
    "nftContractAddress": "0x...",
    "bridgeContractAddress": "0x..."
  }
}
```

### Step 3: Deploy to Arbitrum Sepolia

```bash
NETWORK=arbitrum-sepolia forge script script/Deploy.s.sol:Deploy --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify
```

Update `deployment.json` with Arbitrum Sepolia addresses:

```json
{
  "arbitrumSepolia": {
    "nftContractAddress": "0x...",
    "bridgeContractAddress": "0x..."
  }
}
```

### Step 4: Configure Bridges

Set trusted senders on both chains:

```bash
# Configure Fuji bridge
NETWORK=fuji forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $FUJI_RPC_URL --broadcast

# Configure Arbitrum Sepolia bridge
NETWORK=arbitrum-sepolia forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
```

### Step 5: Mint Test NFT

Mint a test NFT on Avalanche Fuji:

```bash
NETWORK=fuji forge script script/MintTestNFT.s.sol:MintTestNFT --rpc-url $FUJI_RPC_URL --broadcast
```

**Test NFT Details**:
- **Token ID**: 1
- **Token URI**: ipfs://QmY7Mhyj3vX5p9KqF2zFvN8gW4xR7jH2nP9sL5kM6tQ8wZ
- **Owner**: Your deployer address

### Step 6: Fund Bridges with LINK

Both bridge contracts need LINK tokens to pay for CCIP fees:

```bash
# Fund Fuji bridge
cast send $FUJI_BRIDGE_ADDRESS "fundWithLink(uint256)" 1000000000000000000 \
  --rpc-url $FUJI_RPC_URL --private-key $PRIVATE_KEY

# Fund Arbitrum Sepolia bridge
cast send $ARBITRUM_SEPOLIA_BRIDGE_ADDRESS "fundWithLink(uint256)" 1000000000000000000 \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

## Usage

### Using Docker (Recommended)

1. **Build and start the container**:
   ```bash
   docker-compose up -d
   ```

2. **Execute a transfer**:
   ```bash
   docker exec ccip-nft-bridge-cli npm run transfer -- \
     --tokenId=1 \
     --from=avalanche-fuji \
     --to=arbitrum-sepolia \
     --receiver=0xYourReceiverAddress
   ```

3. **View logs**:
   ```bash
   docker exec ccip-nft-bridge-cli cat logs/transfers.log
   ```

4. **View transfer records**:
   ```bash
   docker exec ccip-nft-bridge-cli cat data/nft_transfers.json
   ```

### Without Docker

```bash
npm run transfer -- \
  --tokenId=1 \
  --from=avalanche-fuji \
  --to=arbitrum-sepolia \
  --receiver=0xYourReceiverAddress
```

### CLI Parameters

- `--tokenId`: The NFT token ID to transfer (required)
- `--from`: Source chain (`avalanche-fuji` or `arbitrum-sepolia`) (required)
- `--to`: Destination chain (`avalanche-fuji` or `arbitrum-sepolia`) (required)
- `--receiver`: Receiver address on destination chain (required)

### Tracking Transfers

After initiating a transfer, you'll receive a CCIP Message ID. Track it on the [CCIP Explorer](https://ccip.chain.link/):

```
https://ccip.chain.link/msg/<message-id>
```

Transfers typically take 5-10 minutes to complete.

## Testing

### Verify NFT Ownership (Source Chain)

```bash
cast call $FUJI_NFT_ADDRESS "ownerOf(uint256)" 1 --rpc-url $FUJI_RPC_URL
```

### Verify NFT Metadata

```bash
cast call $FUJI_NFT_ADDRESS "tokenURI(uint256)" 1 --rpc-url $FUJI_RPC_URL
```

### Check Transfer Cost

```bash
cast call $FUJI_BRIDGE_ADDRESS "estimateTransferCost(uint64)" $ARBITRUM_SEPOLIA_CHAIN_SELECTOR --rpc-url $FUJI_RPC_URL
```

### Verify NFT on Destination Chain

After the transfer completes:

```bash
cast call $ARBITRUM_SEPOLIA_NFT_ADDRESS "ownerOf(uint256)" 1 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## Project Structure

```
.
├── src/
│   ├── CrossChainNFT.sol          # ERC-721 NFT contract
│   └── CCIPNFTBridge.sol          # CCIP bridge contract
├── script/
│   ├── Deploy.s.sol               # Deployment script
│   ├── MintTestNFT.s.sol         # Test NFT minting script
│   └── ConfigureBridge.s.sol      # Bridge configuration script
├── cli/
│   └── index.js                   # Node.js CLI tool
├── data/
│   └── nft_transfers.json         # Transfer records (generated)
├── logs/
│   └── transfers.log              # Transfer logs (generated)
├── out/                           # Compiled contracts (generated)
├── Dockerfile                     # Docker container definition
├── docker-compose.yml             # Docker Compose configuration
├── foundry.toml                   # Foundry configuration
├── package.json                   # Node.js dependencies
├── deployment.json                # Deployed contract addresses
├── .env.example                   # Environment variables template
└── README.md                      # This file
```

## Security Considerations

### Access Control

- **Minting**: Only the bridge contract can mint NFTs
- **Bridge Configuration**: Only the owner can set trusted senders
- **NFT Burning**: Only the token owner or approved address can burn

### Best Practices Implemented

1. ✅ **Trusted Sender Validation**: Bridge verifies message source
2. ✅ **Idempotency**: Prevents duplicate minting
3. ✅ **Reentrancy Protection**: Uses OpenZeppelin's secure patterns
4. ✅ **Gas Limits**: Set appropriate gas limits for cross-chain calls
5. ✅ **Event Logging**: Comprehensive event emission for tracking

### Important Warnings

- **Never commit your private key**: Use `.env` file and keep it secret
- **Test on testnets first**: Always test thoroughly before mainnet
- **Fund bridges adequately**: Ensure sufficient LINK for transfers
- **Monitor transactions**: Use CCIP Explorer to track cross-chain messages

## Troubleshooting

### Common Issues

1. **"Insufficient LINK balance" error**:
   - Solution: Fund the bridge contract with LINK tokens

2. **"Caller is not the bridge" error**:
   - Solution: Ensure `setBridge()` was called with correct address

3. **"Untrusted sender" error**:
   - Solution: Configure trusted senders using `ConfigureBridge.s.sol`

4. **NFT doesn't arrive on destination**:
   - Check CCIP Explorer for message status
   - Verify bridge has sufficient LINK
   - Ensure trusted senders are configured correctly

5. **Docker container not starting**:
   - Run `docker-compose down -v` and try again
   - Check Docker logs: `docker logs ccip-nft-bridge-cli`

### Useful Commands

```bash
# Check LINK balance of bridge
cast call $LINK_TOKEN_ADDRESS "balanceOf(address)" $BRIDGE_ADDRESS --rpc-url $RPC_URL

# Check if bridge is set in NFT contract
cast call $NFT_ADDRESS "bridge()" --rpc-url $RPC_URL

# Check trusted sender
cast call $BRIDGE_ADDRESS "trustedSenders(uint64)" $CHAIN_SELECTOR --rpc-url $RPC_URL

# View recent transactions
cast receipt $TX_HASH --rpc-url $RPC_URL
```

## Resources

### Documentation

- [Chainlink CCIP Documentation](https://docs.chain.link/ccip)
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Ethers.js Documentation](https://docs.ethers.org/)

### Tools

- [CCIP Explorer](https://ccip.chain.link/)
- [Avalanche Explorer](https://testnet.snowtrace.io/)
- [Arbitrum Sepolia Explorer](https://sepolia.arbiscan.io/)
- [Chainlink Faucets](https://faucets.chain.link/)

### Contract Addresses

#### Avalanche Fuji
- CCIP Router: `0xF694E193200268f9a4868e4Aa017A0118C9a8177`
- LINK Token: `0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846`
- Chain Selector: `14767482510784806043`

#### Arbitrum Sepolia
- CCIP Router: `0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165`
- LINK Token: `0xb1D4538B4571d411F07960EF2838Ce337FE1E80E`
- Chain Selector: `3478487238524512106`

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Acknowledgments

- Chainlink for CCIP infrastructure
- OpenZeppelin for secure contract libraries
- Foundry team for excellent development tools

---

**Note**: This is a testnet project for educational purposes. Always conduct thorough security audits before deploying to mainnet.
