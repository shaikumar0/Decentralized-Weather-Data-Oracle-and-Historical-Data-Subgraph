// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CCIPNFTBridge.sol";
import "../src/CrossChainNFT.sol";

/**
 * @title CCIPNFTBridgeTest
 * @notice Unit tests for CCIPNFTBridge contract
 * @dev Uses mocked CCIP interfaces for testing
 */
contract CCIPNFTBridgeTest is Test {
    CCIPNFTBridge public bridge;
    CrossChainNFT public nft;
    
    address public owner;
    address public router;
    address public linkToken;
    address public user;

    uint64 constant DESTINATION_CHAIN_SELECTOR = 3478487238524512106;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        router = makeAddr("router");
        linkToken = makeAddr("linkToken");

        // Deploy NFT contract
        nft = new CrossChainNFT("Test NFT", "TNFT", owner);

        // Deploy Bridge contract
        bridge = new CCIPNFTBridge(router, linkToken, address(nft), owner);

        // Set bridge in NFT contract
        nft.setBridge(address(bridge));
    }

    function testInitialState() public {
        assertEq(address(bridge.nft()), address(nft));
        assertEq(address(bridge.router()), router);
        assertEq(address(bridge.linkToken()), linkToken);
    }

    function testSetTrustedSender() public {
        address trustedSender = makeAddr("trustedSender");
        
        bridge.setTrustedSender(DESTINATION_CHAIN_SELECTOR, trustedSender);
        
        assertEq(bridge.trustedSenders(DESTINATION_CHAIN_SELECTOR), trustedSender);
    }

    function testSetTrustedSenderFailsForNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.setTrustedSender(DESTINATION_CHAIN_SELECTOR, makeAddr("trustedSender"));
    }

    function testSetTrustedSenderFailsForZeroAddress() public {
        vm.expectRevert("Invalid sender address");
        bridge.setTrustedSender(DESTINATION_CHAIN_SELECTOR, address(0));
    }

    function testOnERC721Received() public {
        bytes4 selector = bridge.onERC721Received(address(0), address(0), 0, "");
        assertEq(selector, bridge.onERC721Received.selector);
    }

    function testWithdrawLink() public {
        // Mock LINK balance
        vm.mockCall(
            linkToken,
            abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)"))),
            abi.encode(true)
        );

        bridge.withdrawLink(user, 1 ether);
    }

    function testWithdrawLinkFailsForNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.withdrawLink(user, 1 ether);
    }
}
