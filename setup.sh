#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}CCIP NFT Bridge Setup Script${NC}"
echo -e "${BLUE}==================================${NC}\n"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "Please copy .env.example to .env and configure it:"
    echo -e "  ${GREEN}cp .env.example .env${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found .env file"

# Load environment variables
source .env

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not configured in .env${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Environment variables loaded\n"

# Install Foundry dependencies
echo -e "${BLUE}Installing Foundry dependencies...${NC}"
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install smartcontractkit/ccip --no-commit
forge install smartcontractkit/chainlink-brownie-contracts --no-commit
echo -e "${GREEN}✓${NC} Foundry dependencies installed\n"

# Install Node.js dependencies
echo -e "${BLUE}Installing Node.js dependencies...${NC}"
npm install
echo -e "${GREEN}✓${NC} Node.js dependencies installed\n"

# Compile contracts
echo -e "${BLUE}Compiling smart contracts...${NC}"
forge build
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Contract compilation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Contracts compiled successfully\n"

# Deploy to Avalanche Fuji
echo -e "${BLUE}Deploying to Avalanche Fuji...${NC}"
NETWORK=fuji forge script script/Deploy.s.sol:Deploy --rpc-url $FUJI_RPC_URL --broadcast
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Deployment to Fuji failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Deployed to Avalanche Fuji\n"

echo -e "${BLUE}Please update deployment.json with the Fuji contract addresses shown above.${NC}"
echo -e "${BLUE}Press Enter when done...${NC}"
read

# Deploy to Arbitrum Sepolia
echo -e "${BLUE}Deploying to Arbitrum Sepolia...${NC}"
NETWORK=arbitrum-sepolia forge script script/Deploy.s.sol:Deploy --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Deployment to Arbitrum Sepolia failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Deployed to Arbitrum Sepolia\n"

echo -e "${BLUE}Please update deployment.json with the Arbitrum Sepolia contract addresses.${NC}"
echo -e "${BLUE}Also update the .env file with all deployed addresses.${NC}"
echo -e "${BLUE}Press Enter when done...${NC}"
read

# Configure bridges
echo -e "${BLUE}Configuring Fuji bridge...${NC}"
NETWORK=fuji forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $FUJI_RPC_URL --broadcast
echo -e "${GREEN}✓${NC} Fuji bridge configured\n"

echo -e "${BLUE}Configuring Arbitrum Sepolia bridge...${NC}"
NETWORK=arbitrum-sepolia forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
echo -e "${GREEN}✓${NC} Arbitrum Sepolia bridge configured\n"

# Mint test NFT
echo -e "${BLUE}Minting test NFT on Avalanche Fuji...${NC}"
NETWORK=fuji forge script script/MintTestNFT.s.sol:MintTestNFT --rpc-url $FUJI_RPC_URL --broadcast
echo -e "${GREEN}✓${NC} Test NFT minted\n"

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==================================${NC}\n"

echo -e "Next steps:"
echo -e "1. Fund both bridge contracts with LINK tokens"
echo -e "2. Build the Docker container: ${GREEN}docker-compose up -d${NC}"
echo -e "3. Transfer an NFT: ${GREEN}docker exec ccip-nft-bridge-cli npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=<address>${NC}"
echo -e "\n${BLUE}Happy bridging! 🌉${NC}\n"
