// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CrossChainNFT.sol";
import "../src/CCIPNFTBridge.sol";

/**
 * @title MintTestNFT
 * @notice Script to mint a test NFT on Avalanche Fuji
 * @dev Run with: NETWORK=fuji forge script script/MintTestNFT.s.sol:MintTestNFT --rpc-url $FUJI_RPC_URL --broadcast
 */
contract MintTestNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load deployment addresses from environment or use deployed addresses
        address nftAddress = vm.envAddress("FUJI_NFT_ADDRESS");
        address bridgeAddress = vm.envAddress("FUJI_BRIDGE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        CrossChainNFT nft = CrossChainNFT(nftAddress);

        // Mint test NFT with tokenId 1
        uint256 tokenId = 1;
        string memory tokenURI = "ipfs://QmY7Mhyj3vX5p9KqF2zFvN8gW4xR7jH2nP9sL5kM6tQ8wZ";

        console.log("Minting test NFT...");
        console.log("Token ID:", tokenId);
        console.log("Token URI:", tokenURI);
        console.log("Recipient:", deployer);

        // Temporarily set deployer as bridge to mint
        nft.setBridge(deployer);
        nft.mint(deployer, tokenId, tokenURI);

        // Set back the actual bridge
        nft.setBridge(bridgeAddress);

        console.log("\nTest NFT minted successfully!");
        console.log("Owner:", nft.ownerOf(tokenId));
        console.log("Token URI:", nft.tokenURI(tokenId));

        vm.stopBroadcast();
    }
}
