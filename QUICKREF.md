# Quick Reference Guide

## Essential Commands

### Setup & Installation
```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install smartcontractkit/ccip --no-commit
forge install smartcontractkit/chainlink-brownie-contracts --no-commit
npm install

# Compile contracts
forge build

# Run tests
forge test -vv
```

### Deployment
```bash
# Deploy to Fuji
NETWORK=fuji forge script script/Deploy.s.sol:Deploy --rpc-url $FUJI_RPC_URL --broadcast

# Deploy to Arbitrum Sepolia
NETWORK=arbitrum-sepolia forge script script/Deploy.s.sol:Deploy --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast

# Configure bridges
NETWORK=fuji forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $FUJI_RPC_URL --broadcast
NETWORK=arbitrum-sepolia forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast

# Mint test NFT
NETWORK=fuji forge script script/MintTestNFT.s.sol:MintTestNFT --rpc-url $FUJI_RPC_URL --broadcast
```

### Fund Bridges with LINK
```bash
# Fuji
cast send $FUJI_BRIDGE_ADDRESS "fundWithLink(uint256)" 1000000000000000000 \
  --rpc-url $FUJI_RPC_URL --private-key $PRIVATE_KEY

# Arbitrum Sepolia
cast send $ARBITRUM_SEPOLIA_BRIDGE_ADDRESS "fundWithLink(uint256)" 1000000000000000000 \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Docker Commands
```bash
# Build and start container
docker-compose up -d --build

# Stop container
docker-compose down

# View logs
docker logs ccip-nft-bridge-cli

# Execute CLI
docker exec ccip-nft-bridge-cli npm run transfer -- \
  --tokenId=1 \
  --from=avalanche-fuji \
  --to=arbitrum-sepolia \
  --receiver=0xYourAddress
```

### Transfer NFT
```bash
# Using Docker
docker exec ccip-nft-bridge-cli npm run transfer -- \
  --tokenId=1 \
  --from=avalanche-fuji \
  --to=arbitrum-sepolia \
  --receiver=0xReceiverAddress

# Without Docker
npm run transfer -- \
  --tokenId=1 \
  --from=avalanche-fuji \
  --to=arbitrum-sepolia \
  --receiver=0xReceiverAddress
```

## Verification Commands

### Check NFT Ownership
```bash
# On Fuji
cast call $FUJI_NFT_ADDRESS "ownerOf(uint256)" 1 --rpc-url $FUJI_RPC_URL

# On Arbitrum Sepolia
cast call $ARBITRUM_SEPOLIA_NFT_ADDRESS "ownerOf(uint256)" 1 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Check Token Metadata
```bash
cast call $FUJI_NFT_ADDRESS "tokenURI(uint256)" 1 --rpc-url $FUJI_RPC_URL
```

### Check Bridge Configuration
```bash
# Check bridge is set in NFT
cast call $FUJI_NFT_ADDRESS "bridge()" --rpc-url $FUJI_RPC_URL

# Check trusted sender (Arbitrum Sepolia selector)
cast call $FUJI_BRIDGE_ADDRESS "trustedSenders(uint64)" 3478487238524512106 --rpc-url $FUJI_RPC_URL

# Check trusted sender (Fuji selector)
cast call $ARBITRUM_SEPOLIA_BRIDGE_ADDRESS "trustedSenders(uint64)" 14767482510784806043 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Check LINK Balance
```bash
# Fuji bridge
cast call 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 \
  "balanceOf(address)" $FUJI_BRIDGE_ADDRESS \
  --rpc-url $FUJI_RPC_URL

# Arbitrum Sepolia bridge
cast call 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E \
  "balanceOf(address)" $ARBITRUM_SEPOLIA_BRIDGE_ADDRESS \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Estimate Transfer Cost
```bash
cast call $FUJI_BRIDGE_ADDRESS \
  "estimateTransferCost(uint64)" 3478487238524512106 \
  --rpc-url $FUJI_RPC_URL
```

## Important Addresses

### Avalanche Fuji
- **CCIP Router**: `0xF694E193200268f9a4868e4Aa017A0118C9a8177`
- **LINK Token**: `0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846`
- **Chain Selector**: `14767482510784806043`
- **Explorer**: https://testnet.snowtrace.io/

### Arbitrum Sepolia
- **CCIP Router**: `0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165`
- **LINK Token**: `0xb1D4538B4571d411F07960EF2838Ce337FE1E80E`
- **Chain Selector**: `3478487238524512106`
- **Explorer**: https://sepolia.arbiscan.io/

## Useful Links

- **CCIP Explorer**: https://ccip.chain.link/
- **Chainlink Faucet**: https://faucets.chain.link/
- **Avalanche Faucet**: https://faucet.avax.network/
- **Arbitrum Faucet**: https://faucet.quicknode.com/arbitrum/sepolia
- **CCIP Docs**: https://docs.chain.link/ccip

## Project Structure
```
.
├── src/                    # Smart contracts
│   ├── CrossChainNFT.sol
│   └── CCIPNFTBridge.sol
├── script/                 # Deployment scripts
│   ├── Deploy.s.sol
│   ├── ConfigureBridge.s.sol
│   └── MintTestNFT.s.sol
├── test/                   # Unit tests
│   ├── CrossChainNFT.t.sol
│   └── CCIPNFTBridge.t.sol
├── cli/                    # Node.js CLI tool
│   └── index.js
├── data/                   # Transfer records
│   └── nft_transfers.json
├── logs/                   # Application logs
│   └── transfers.log
├── out/                    # Compiled contracts (generated)
├── Dockerfile              # CLI container
├── docker-compose.yml      # Docker orchestration
├── foundry.toml            # Foundry config
├── package.json            # Node dependencies
├── deployment.json         # Contract addresses
└── .env                    # Environment variables
```

## Environment Variables

Required in `.env`:
```bash
PRIVATE_KEY=your_private_key
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
FUJI_NFT_ADDRESS=0x...
FUJI_BRIDGE_ADDRESS=0x...
ARBITRUM_SEPOLIA_NFT_ADDRESS=0x...
ARBITRUM_SEPOLIA_BRIDGE_ADDRESS=0x...
```

## Common Issues

### "Insufficient LINK balance"
```bash
# Check LINK balance
cast call $LINK_TOKEN "balanceOf(address)" $BRIDGE_ADDRESS --rpc-url $RPC_URL

# Fund bridge
cast send $BRIDGE_ADDRESS "fundWithLink(uint256)" 1000000000000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### "Untrusted sender"
```bash
# Run configuration script
NETWORK=fuji forge script script/ConfigureBridge.s.sol:ConfigureBridge \
  --rpc-url $FUJI_RPC_URL --broadcast
```

### "Caller is not the bridge"
```bash
# Verify bridge is set
cast call $NFT_ADDRESS "bridge()" --rpc-url $RPC_URL

# Set bridge if needed
cast send $NFT_ADDRESS "setBridge(address)" $BRIDGE_ADDRESS \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## Testing Flow

1. **Deploy contracts** to both chains
2. **Configure bridges** with trusted senders
3. **Mint test NFT** on source chain
4. **Fund bridges** with LINK tokens
5. **Execute transfer** via CLI
6. **Track on CCIP Explorer**
7. **Verify** on destination chain

## CLI Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--tokenId` | Token ID to transfer | `1` |
| `--from` | Source chain | `avalanche-fuji` |
| `--to` | Destination chain | `arbitrum-sepolia` |
| `--receiver` | Receiver address | `0x1234...` |

## Gas Estimates

- Deploy NFT: ~2.5M gas
- Deploy Bridge: ~3M gas
- Mint NFT: ~150k gas
- Send NFT: ~200k gas + 0.5-2 LINK
- Receive NFT: ~150k gas (paid by sender)

## Support Resources

- GitHub Issues: Report bugs
- Discord: https://discord.gg/chainlink
- Documentation: See README.md, DEPLOYMENT.md, ARCHITECTURE.md
- CCIP Docs: https://docs.chain.link/ccip
