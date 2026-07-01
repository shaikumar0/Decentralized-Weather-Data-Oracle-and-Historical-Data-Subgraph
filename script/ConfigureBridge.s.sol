// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CCIPNFTBridge.sol";

/**
 * @title ConfigureBridge
 * @notice Script to configure trusted senders between bridges
 * @dev Run after deploying to both chains
 */
contract ConfigureBridge is Script {
    uint64 constant FUJI_CHAIN_SELECTOR = 14767482510784806043;
    uint64 constant ARBITRUM_SEPOLIA_CHAIN_SELECTOR = 3478487238524512106;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address fujiBridge = vm.envAddress("FUJI_BRIDGE_ADDRESS");
        address arbitrumSepoliaBridge = vm.envAddress("ARBITRUM_SEPOLIA_BRIDGE_ADDRESS");

        string memory network = vm.envString("NETWORK");

        vm.startBroadcast(deployerPrivateKey);

        if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("fuji"))) {
            // Configure Fuji bridge to trust Arbitrum Sepolia bridge
            CCIPNFTBridge(fujiBridge).setTrustedSender(
                ARBITRUM_SEPOLIA_CHAIN_SELECTOR, arbitrumSepoliaBridge
            );
            console.log("Configured Fuji bridge to trust Arbitrum Sepolia bridge");
        } else if (
            keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("arbitrum-sepolia"))
        ) {
            // Configure Arbitrum Sepolia bridge to trust Fuji bridge
            CCIPNFTBridge(arbitrumSepoliaBridge).setTrustedSender(FUJI_CHAIN_SELECTOR, fujiBridge);
            console.log("Configured Arbitrum Sepolia bridge to trust Fuji bridge");
        }

        vm.stopBroadcast();
    }
}
