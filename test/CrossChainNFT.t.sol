// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CrossChainNFT.sol";
import "../src/CCIPNFTBridge.sol";

/**
 * @title CrossChainNFTTest
 * @notice Unit tests for CrossChainNFT contract
 */
contract CrossChainNFTTest is Test {
    CrossChainNFT public nft;
    address public owner;
    address public bridge;
    address public user;

    function setUp() public {
        owner = address(this);
        bridge = makeAddr("bridge");
        user = makeAddr("user");

        nft = new CrossChainNFT("Test NFT", "TNFT", owner);
        nft.setBridge(bridge);
    }

    function testInitialState() public {
        assertEq(nft.name(), "Test NFT");
        assertEq(nft.symbol(), "TNFT");
        assertEq(nft.bridge(), bridge);
    }

    function testSetBridge() public {
        address newBridge = makeAddr("newBridge");
        nft.setBridge(newBridge);
        assertEq(nft.bridge(), newBridge);
    }

    function testSetBridgeFailsForNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        nft.setBridge(makeAddr("newBridge"));
    }

    function testMintFromBridge() public {
        uint256 tokenId = 1;
        string memory tokenURI = "ipfs://test";

        vm.prank(bridge);
        nft.mint(user, tokenId, tokenURI);

        assertEq(nft.ownerOf(tokenId), user);
        assertEq(nft.tokenURI(tokenId), tokenURI);
    }

    function testMintFailsForNonBridge() public {
        vm.prank(user);
        vm.expectRevert("Caller is not the bridge");
        nft.mint(user, 1, "ipfs://test");
    }

    function testBurn() public {
        uint256 tokenId = 1;
        string memory tokenURI = "ipfs://test";

        // Mint token
        vm.prank(bridge);
        nft.mint(user, tokenId, tokenURI);

        // Burn token
        vm.prank(user);
        nft.burn(tokenId);

        // Verify token no longer exists
        vm.expectRevert();
        nft.ownerOf(tokenId);
    }

    function testBurnFailsForNonOwner() public {
        uint256 tokenId = 1;

        // Mint token
        vm.prank(bridge);
        nft.mint(user, tokenId, "ipfs://test");

        // Try to burn from different address
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        nft.burn(tokenId);
    }
}
