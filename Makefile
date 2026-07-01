# Makefile for CCIP NFT Bridge

.PHONY: help install build test clean deploy-fuji deploy-arbitrum configure mint-test docker-up docker-down transfer

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install all dependencies
	@echo "Installing Foundry dependencies..."
	@forge install OpenZeppelin/openzeppelin-contracts --no-commit
	@forge install smartcontractkit/ccip --no-commit
	@forge install smartcontractkit/chainlink-brownie-contracts --no-commit
	@echo "Installing Node.js dependencies..."
	@npm install
	@echo "✓ Dependencies installed"

build: ## Compile smart contracts
	@echo "Compiling contracts..."
	@forge build
	@echo "✓ Contracts compiled"

test: ## Run smart contract tests
	@echo "Running tests..."
	@forge test -vv
	@echo "✓ Tests completed"

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@forge clean
	@rm -rf out cache
	@echo "✓ Clean completed"

deploy-fuji: ## Deploy contracts to Avalanche Fuji
	@echo "Deploying to Avalanche Fuji..."
	@NETWORK=fuji forge script script/Deploy.s.sol:Deploy --rpc-url $(FUJI_RPC_URL) --broadcast
	@echo "✓ Deployment completed"

deploy-arbitrum: ## Deploy contracts to Arbitrum Sepolia
	@echo "Deploying to Arbitrum Sepolia..."
	@NETWORK=arbitrum-sepolia forge script script/Deploy.s.sol:Deploy --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --broadcast
	@echo "✓ Deployment completed"

configure: ## Configure bridges (set trusted senders)
	@echo "Configuring Fuji bridge..."
	@NETWORK=fuji forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $(FUJI_RPC_URL) --broadcast
	@echo "Configuring Arbitrum Sepolia bridge..."
	@NETWORK=arbitrum-sepolia forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --broadcast
	@echo "✓ Configuration completed"

mint-test: ## Mint test NFT on Fuji
	@echo "Minting test NFT..."
	@NETWORK=fuji forge script script/MintTestNFT.s.sol:MintTestNFT --rpc-url $(FUJI_RPC_URL) --broadcast
	@echo "✓ Test NFT minted"

docker-up: ## Start Docker container
	@echo "Starting Docker container..."
	@docker-compose up -d --build
	@echo "✓ Container started"

docker-down: ## Stop Docker container
	@echo "Stopping Docker container..."
	@docker-compose down
	@echo "✓ Container stopped"

docker-logs: ## View Docker container logs
	@docker logs ccip-nft-bridge-cli

transfer: ## Transfer NFT (requires TOKEN_ID, RECEIVER)
	@docker exec ccip-nft-bridge-cli npm run transfer -- \
		--tokenId=$(TOKEN_ID) \
		--from=avalanche-fuji \
		--to=arbitrum-sepolia \
		--receiver=$(RECEIVER)

verify-fuji: ## Verify NFT on Fuji
	@cast call $(FUJI_NFT_ADDRESS) "ownerOf(uint256)" $(TOKEN_ID) --rpc-url $(FUJI_RPC_URL)

verify-arbitrum: ## Verify NFT on Arbitrum Sepolia
	@cast call $(ARBITRUM_SEPOLIA_NFT_ADDRESS) "ownerOf(uint256)" $(TOKEN_ID) --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL)

check-link-fuji: ## Check LINK balance of Fuji bridge
	@cast call $(LINK_TOKEN_FUJI) "balanceOf(address)" $(FUJI_BRIDGE_ADDRESS) --rpc-url $(FUJI_RPC_URL)

check-link-arbitrum: ## Check LINK balance of Arbitrum bridge
	@cast call $(LINK_TOKEN_ARBITRUM_SEPOLIA) "balanceOf(address)" $(ARBITRUM_SEPOLIA_BRIDGE_ADDRESS) --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL)
