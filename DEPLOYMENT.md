# Deployment Guide

This guide walks you through deploying the CCIP NFT Bridge from scratch.

## Prerequisites

### 1. Install Required Tools

- **Foundry**: 
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```

- **Node.js**: [Download from nodejs.org](https://nodejs.org/)

- **Docker**: [Download from docker.com](https://www.docker.com/get-started)

### 2. Get Testnet Funds

#### Avalanche Fuji
- Visit [Avalanche Faucet](https://faucet.avax.network/)
- Request testnet AVAX

#### Arbitrum Sepolia
- Visit [Arbitrum Faucet](https://faucet.quicknode.com/arbitrum/sepolia)
- Request testnet ETH

#### LINK Tokens
- Visit [Chainlink Faucet](https://faucets.chain.link/)
- Request LINK on both Fuji and Arbitrum Sepolia

## Step-by-Step Deployment

### 1. Clone and Setup

```bash
git clone <repository-url>
cd "Chainlink CCIP Cross-Chain NFT Transfer with Metadata Preservation"
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` file:

```bash
PRIVATE_KEY=your_private_key_without_0x_prefix
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
```

### 3. Install Dependencies

```bash
# Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install smartcontractkit/ccip --no-commit
forge install smartcontractkit/chainlink-brownie-contracts --no-commit

# Install Node.js dependencies
npm install
```

### 4. Compile Contracts

```bash
forge build
```

Expected output:
```
[⠊] Compiling...
[⠒] Compiling 50 files with 0.8.19
[⠢] Solc 0.8.19 finished in 3.45s
Compiler run successful!
```

### 5. Deploy to Avalanche Fuji

```bash
NETWORK=fuji forge script script/Deploy.s.sol:Deploy \
  --rpc-url $FUJI_RPC_URL \
  --broadcast \
  --verify
```

**Save the output addresses!** You'll see something like:

```
NFT Contract deployed at: 0xAbC123...
Bridge Contract deployed at: 0xDeF456...
```

Update `deployment.json`:

```json
{
  "avalancheFuji": {
    "nftContractAddress": "0xAbC123...",
    "bridgeContractAddress": "0xDeF456..."
  }
}
```

### 6. Deploy to Arbitrum Sepolia

```bash
NETWORK=arbitrum-sepolia forge script script/Deploy.s.sol:Deploy \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

Update `deployment.json` with Arbitrum addresses:

```json
{
  "avalancheFuji": {
    "nftContractAddress": "0xAbC123...",
    "bridgeContractAddress": "0xDeF456..."
  },
  "arbitrumSepolia": {
    "nftContractAddress": "0xGhI789...",
    "bridgeContractAddress": "0xJkL012..."
  }
}
```

### 7. Update Environment File

Add deployed addresses to `.env`:

```bash
FUJI_NFT_ADDRESS=0xAbC123...
FUJI_BRIDGE_ADDRESS=0xDeF456...
ARBITRUM_SEPOLIA_NFT_ADDRESS=0xGhI789...
ARBITRUM_SEPOLIA_BRIDGE_ADDRESS=0xJkL012...
```

### 8. Configure Bridges

Set trusted senders on both chains:

```bash
# Configure Fuji bridge
NETWORK=fuji forge script script/ConfigureBridge.s.sol:ConfigureBridge \
  --rpc-url $FUJI_RPC_URL \
  --broadcast

# Configure Arbitrum Sepolia bridge
NETWORK=arbitrum-sepolia forge script script/ConfigureBridge.s.sol:ConfigureBridge \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast
```

### 9. Fund Bridges with LINK

Both bridges need LINK tokens to pay for CCIP fees:

```bash
# Fuji bridge
cast send $FUJI_BRIDGE_ADDRESS \
  "fundWithLink(uint256)" 1000000000000000000 \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY

# Arbitrum Sepolia bridge
cast send $ARBITRUM_SEPOLIA_BRIDGE_ADDRESS \
  "fundWithLink(uint256)" 1000000000000000000 \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Note**: You need to have LINK tokens in your wallet first!

### 10. Mint Test NFT

```bash
NETWORK=fuji forge script script/MintTestNFT.s.sol:MintTestNFT \
  --rpc-url $FUJI_RPC_URL \
  --broadcast
```

Verify the NFT was minted:

```bash
cast call $FUJI_NFT_ADDRESS \
  "ownerOf(uint256)" 1 \
  --rpc-url $FUJI_RPC_URL
```

### 11. Build Docker Container

```bash
docker-compose up -d --build
```

Verify the container is running:

```bash
docker ps
```

## Verification Steps

### Check Contract Deployment

```bash
# Verify NFT contract on Fuji
cast call $FUJI_NFT_ADDRESS "name()" --rpc-url $FUJI_RPC_URL

# Verify bridge is set
cast call $FUJI_NFT_ADDRESS "bridge()" --rpc-url $FUJI_RPC_URL
```

### Check Bridge Configuration

```bash
# Check trusted sender on Fuji
cast call $FUJI_BRIDGE_ADDRESS \
  "trustedSenders(uint64)" 3478487238524512106 \
  --rpc-url $FUJI_RPC_URL

# Check trusted sender on Arbitrum Sepolia
cast call $ARBITRUM_SEPOLIA_BRIDGE_ADDRESS \
  "trustedSenders(uint64)" 14767482510784806043 \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Check LINK Balance

```bash
# Fuji bridge LINK balance
cast call 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 \
  "balanceOf(address)" $FUJI_BRIDGE_ADDRESS \
  --rpc-url $FUJI_RPC_URL

# Arbitrum Sepolia bridge LINK balance
cast call 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E \
  "balanceOf(address)" $ARBITRUM_SEPOLIA_BRIDGE_ADDRESS \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## Test Transfer

Execute your first cross-chain transfer:

```bash
docker exec ccip-nft-bridge-cli npm run transfer -- \
  --tokenId=1 \
  --from=avalanche-fuji \
  --to=arbitrum-sepolia \
  --receiver=0xYourReceiverAddress
```

Track the transfer on [CCIP Explorer](https://ccip.chain.link/).

## Troubleshooting

### "Insufficient LINK balance" Error

1. Check LINK balance in your wallet
2. Approve LINK spending for the bridge
3. Call `fundWithLink()` to fund the bridge

### "Untrusted sender" Error

1. Verify trusted senders are configured
2. Re-run ConfigureBridge script
3. Check chain selectors are correct

### "Transaction reverted" Error

1. Check you have enough gas tokens (AVAX/ETH)
2. Verify contract addresses in deployment.json
3. Ensure NFT is owned by sender

## Next Steps

- Monitor your transfers in `logs/transfers.log`
- View transfer records in `data/nft_transfers.json`
- Try transferring back from Arbitrum Sepolia to Fuji
- Explore the CCIP Explorer for message tracking

## Support

- [Chainlink Documentation](https://docs.chain.link/ccip)
- [Foundry Book](https://book.getfoundry.sh/)
- [CCIP Discord](https://discord.gg/chainlink)
