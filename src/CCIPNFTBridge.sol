// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./CrossChainNFT.sol";

/**
 * @title CCIPNFTBridge
 * @notice Cross-chain NFT bridge using Chainlink CCIP
 * @dev Handles burn-and-mint mechanism for NFT transfers across chains
 */
contract CCIPNFTBridge is CCIPReceiver, IERC721Receiver, Ownable {
    // Contract dependencies
    CrossChainNFT public immutable nft;
    IRouterClient public router;
    IERC20 public linkToken;

    // Mapping to track allowed source chains and their bridge addresses
    mapping(uint64 => address) public trustedSenders;

    // Events
    event NFTSent(
        bytes32 indexed messageId,
        uint64 destinationChainSelector,
        address receiver,
        uint256 tokenId,
        string tokenURI
    );

    event NFTReceived(
        bytes32 indexed messageId,
        uint64 sourceChainSelector,
        address sender,
        address receiver,
        uint256 tokenId,
        string tokenURI
    );

    event TrustedSenderSet(uint64 chainSelector, address sender);

    /**
     * @notice Constructor to initialize the bridge
     * @param _router CCIP Router address
     * @param _link LINK token address
     * @param _nft CrossChainNFT contract address
     * @param initialOwner Owner address for the bridge
     */
    constructor(address _router, address _link, address _nft, address initialOwner)
        CCIPReceiver(_router)
        Ownable(initialOwner)
    {
        router = IRouterClient(_router);
        linkToken = IERC20(_link);
        nft = CrossChainNFT(_nft);
    }

    /**
     * @notice Set trusted sender for a specific chain
     * @param chainSelector The chain selector
     * @param sender The trusted bridge address on that chain
     */
    function setTrustedSender(uint64 chainSelector, address sender) external onlyOwner {
        require(sender != address(0), "Invalid sender address");
        trustedSenders[chainSelector] = sender;
        emit TrustedSenderSet(chainSelector, sender);
    }

    /**
     * @notice Main function to initiate the NFT transfer
     * @param destinationChainSelector The destination chain selector
     * @param receiver The receiver address on destination chain
     * @param tokenId The NFT token ID to transfer
     * @return messageId The CCIP message ID
     */
    function sendNFT(uint64 destinationChainSelector, address receiver, uint256 tokenId)
        external
        returns (bytes32 messageId)
    {
        require(receiver != address(0), "Invalid receiver address");
        require(trustedSenders[destinationChainSelector] != address(0), "Destination chain not supported");

        // Get the token URI before burning
        string memory tokenURI_ = nft.tokenURI(tokenId);

        // Transfer NFT to bridge (will be burned on this chain to maintain supply)
        IERC721(address(nft)).transferFrom(msg.sender, address(this), tokenId);

        // Burn the NFT on source chain
        nft.burn(tokenId);

        // Encode the message data
        bytes memory data = abi.encode(receiver, tokenId, tokenURI_);

        // Build the CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(trustedSenders[destinationChainSelector]),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000})
            ),
            feeToken: address(linkToken)
        });

        // Get the fee
        uint256 fees = router.getFee(destinationChainSelector, message);

        // Approve the router to spend LINK tokens
        require(linkToken.balanceOf(address(this)) >= fees, "Insufficient LINK balance");
        linkToken.approve(address(router), fees);

        // Send the message
        messageId = router.ccipSend(destinationChainSelector, message);

        emit NFTSent(messageId, destinationChainSelector, receiver, tokenId, tokenURI_);

        return messageId;
    }

    /**
     * @notice Callback function to receive messages from CCIP Router
     * @param message The CCIP message
     */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // Decode sender address
        address sender = abi.decode(message.sender, (address));

        // Verify the sender is trusted
        require(trustedSenders[message.sourceChainSelector] == sender, "Untrusted sender");

        // Decode the message data
        (address receiver, uint256 tokenId, string memory tokenURI_) = abi.decode(
            message.data, (address, uint256, string)
        );

        // Check if token already exists (idempotency)
        try nft.ownerOf(tokenId) returns (address) {
            // Token already exists, do not mint again
            revert("Token already minted");
        } catch {
            // Token doesn't exist, proceed with minting
            nft.mint(receiver, tokenId, tokenURI_);
        }

        emit NFTReceived(
            message.messageId, message.sourceChainSelector, sender, receiver, tokenId, tokenURI_
        );
    }

    /**
     * @notice Estimate transfer cost in LINK tokens
     * @param destinationChainSelector The destination chain selector
     * @return The estimated cost in LINK
     */
    function estimateTransferCost(uint64 destinationChainSelector) external view returns (uint256) {
        require(trustedSenders[destinationChainSelector] != address(0), "Destination chain not supported");

        // Create a sample message to estimate cost
        bytes memory data = abi.encode(address(0), uint256(0), "");

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(trustedSenders[destinationChainSelector]),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000})
            ),
            feeToken: address(linkToken)
        });

        return router.getFee(destinationChainSelector, message);
    }

    /**
     * @notice Required for safe NFT transfers to this contract
     */
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Withdraw LINK tokens from the contract
     * @param to The address to withdraw to
     * @param amount The amount to withdraw
     */
    function withdrawLink(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(linkToken.transfer(to, amount), "Transfer failed");
    }

    /**
     * @notice Fund the contract with LINK tokens
     * @param amount The amount of LINK to deposit
     */
    function fundWithLink(uint256 amount) external {
        require(linkToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}
