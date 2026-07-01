// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CrossChainNFT.sol";
import "../src/CCIPNFTBridge.sol";

/**
 * @title Deploy
 * @notice Deployment script for CrossChainNFT and CCIPNFTBridge contracts
 * @dev Run with: forge script script/Deploy.s.sol:Deploy --rpc-url <rpc_url> --broadcast
 */
contract Deploy is Script {
    // Avalanche Fuji addresses
    address constant FUJI_ROUTER = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address constant FUJI_LINK = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    uint64 constant FUJI_CHAIN_SELECTOR = 14767482510784806043;

    // Arbitrum Sepolia addresses
    address constant ARBITRUM_SEPOLIA_ROUTER = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address constant ARBITRUM_SEPOLIA_LINK = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    uint64 constant ARBITRUM_SEPOLIA_CHAIN_SELECTOR = 3478487238524512106;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Check which network we're deploying to
        string memory network = vm.envString("NETWORK");

        if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("fuji"))) {
            deployToFuji(deployer);
        } else if (
            keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("arbitrum-sepolia"))
        ) {
            deployToArbitrumSepolia(deployer);
        } else {
            revert("Invalid network. Use 'fuji' or 'arbitrum-sepolia'");
        }

        vm.stopBroadcast();
    }

    function deployToFuji(address deployer) internal {
        console.log("Deploying to Avalanche Fuji...");
        console.log("Deployer:", deployer);

        // Deploy NFT contract
        CrossChainNFT nft = new CrossChainNFT("CrossChain NFT", "CCNFT", deployer);
        console.log("NFT Contract deployed at:", address(nft));

        // Deploy Bridge contract
        CCIPNFTBridge bridge = new CCIPNFTBridge(FUJI_ROUTER, FUJI_LINK, address(nft), deployer);
        console.log("Bridge Contract deployed at:", address(bridge));

        // Set bridge in NFT contract
        nft.setBridge(address(bridge));
        console.log("Bridge set in NFT contract");

        // Set trusted sender for Arbitrum Sepolia (will need to update after deploying there)
        console.log("\nIMPORTANT: After deploying to Arbitrum Sepolia, run:");
        console.log(
            "cast send <FUJI_BRIDGE_ADDRESS> \"setTrustedSender(uint64,address)\" <ARBITRUM_SEPOLIA_CHAIN_SELECTOR> <ARBITRUM_SEPOLIA_BRIDGE_ADDRESS> --rpc-url $FUJI_RPC_URL --private-key $PRIVATE_KEY"
        );

        // Log deployment info
        console.log("\n=== Deployment Summary ===");
        console.log("Network: Avalanche Fuji");
        console.log("NFT Contract:", address(nft));
        console.log("Bridge Contract:", address(bridge));
        console.log("CCIP Router:", FUJI_ROUTER);
        console.log("LINK Token:", FUJI_LINK);
    }

    function deployToArbitrumSepolia(address deployer) internal {
        console.log("Deploying to Arbitrum Sepolia...");
        console.log("Deployer:", deployer);

        // Deploy NFT contract
        CrossChainNFT nft = new CrossChainNFT("CrossChain NFT", "CCNFT", deployer);
        console.log("NFT Contract deployed at:", address(nft));

        // Deploy Bridge contract
        CCIPNFTBridge bridge =
            new CCIPNFTBridge(ARBITRUM_SEPOLIA_ROUTER, ARBITRUM_SEPOLIA_LINK, address(nft), deployer);
        console.log("Bridge Contract deployed at:", address(bridge));

        // Set bridge in NFT contract
        nft.setBridge(address(bridge));
        console.log("Bridge set in NFT contract");

        // Set trusted sender for Avalanche Fuji (will need to update with Fuji bridge address)
        console.log("\nIMPORTANT: Set the Fuji bridge as trusted sender:");
        console.log(
            "cast send <ARBITRUM_SEPOLIA_BRIDGE_ADDRESS> \"setTrustedSender(uint64,address)\" <FUJI_CHAIN_SELECTOR> <FUJI_BRIDGE_ADDRESS> --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY"
        );

        // Log deployment info
        console.log("\n=== Deployment Summary ===");
        console.log("Network: Arbitrum Sepolia");
        console.log("NFT Contract:", address(nft));
        console.log("Bridge Contract:", address(bridge));
        console.log("CCIP Router:", ARBITRUM_SEPOLIA_ROUTER);
        console.log("LINK Token:", ARBITRUM_SEPOLIA_LINK);
    }
}
