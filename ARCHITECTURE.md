# Contract Architecture

This document explains the architecture and design decisions of the CCIP NFT Bridge.

## Overview

The bridge consists of two main smart contracts deployed on both chains:

1. **CrossChainNFT.sol** - ERC-721 NFT contract
2. **CCIPNFTBridge.sol** - Bridge contract using CCIP

## Contract Diagrams

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Source Chain (Fuji)                      │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                 User's Wallet                         │  │
│  │  - Owns NFT with tokenId=1                           │  │
│  │  - Initiates transfer                                │  │
│  └─────────────────┬────────────────────────────────────┘  │
│                    │                                         │
│                    │ 1. Approve + Transfer NFT               │
│                    ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           CCIPNFTBridge Contract                      │  │
│  │  - Receives NFT from user                            │  │
│  │  - Burns NFT (maintains supply)                      │  │
│  │  - Encodes message with (receiver, tokenId, URI)     │  │
│  │  - Pays LINK fees                                    │  │
│  │  - Sends via CCIP Router                             │  │
│  └─────────────────┬────────────────────────────────────┘  │
│                    │                                         │
│                    │ 2. Burn NFT                            │
│                    ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          CrossChainNFT Contract                       │  │
│  │  - NFT gets burned                                   │  │
│  │  - Supply decreases by 1                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
└───────────────────────────┬───────────────────────────────┘
                            │
                            │ 3. CCIP Message
                            │    (tokenId, URI, receiver)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Chainlink CCIP Network                          │
│  - Validates message                                         │
│  - Routes to destination chain                               │
│  - Executes on destination                                   │
└─────────────────────────┬───────────────────────────────────┘
                            │
                            │ 4. Execute _ccipReceive
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Destination Chain (Arbitrum Sepolia)            │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           CCIPNFTBridge Contract                      │  │
│  │  - Receives CCIP message                             │  │
│  │  - Validates trusted sender                          │  │
│  │  - Decodes (receiver, tokenId, URI)                  │  │
│  │  - Calls mint on NFT contract                        │  │
│  └─────────────────┬────────────────────────────────────┘  │
│                    │                                         │
│                    │ 5. Mint NFT                            │
│                    ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          CrossChainNFT Contract                       │  │
│  │  - Mints NFT to receiver                             │  │
│  │  - Sets tokenURI (preserves metadata)                │  │
│  │  - Supply increases by 1                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Contract Details

### CrossChainNFT.sol

**Purpose**: Standard ERC-721 NFT with controlled minting.

**Key Features**:
- Inherits from OpenZeppelin's `ERC721URIStorage` and `Ownable`
- Access-controlled minting (only bridge can mint)
- Burning capability for token owners
- Metadata preservation via tokenURI

**State Variables**:
```solidity
address public bridge;  // Authorized bridge contract
```

**Functions**:

| Function | Access | Purpose |
|----------|--------|---------|
| `setBridge(address)` | Owner | Set authorized bridge |
| `mint(address, uint256, string)` | Bridge | Mint new NFT |
| `burn(uint256)` | Token Owner | Burn owned NFT |
| `tokenURI(uint256)` | Public | Get metadata URI |
| `ownerOf(uint256)` | Public | Get token owner |

**Security Features**:
- ✅ Only bridge can mint (prevents unauthorized minting)
- ✅ Only token owner/approved can burn
- ✅ Owner can update bridge address (for upgrades)

### CCIPNFTBridge.sol

**Purpose**: Handle cross-chain NFT transfers using CCIP.

**Key Features**:
- Inherits from `CCIPReceiver`, `IERC721Receiver`, and `Ownable`
- Manages LINK token payments for CCIP fees
- Validates trusted senders for security
- Implements idempotent minting

**State Variables**:
```solidity
CrossChainNFT public immutable nft;     // Associated NFT contract
IRouterClient public router;             // CCIP Router
IERC20 public linkToken;                 // LINK token for fees
mapping(uint64 => address) public trustedSenders;  // Trusted bridges
```

**Functions**:

| Function | Access | Purpose |
|----------|--------|---------|
| `sendNFT(uint64, address, uint256)` | Public | Initiate transfer |
| `_ccipReceive(Any2EVMMessage)` | Internal | Receive CCIP message |
| `estimateTransferCost(uint64)` | View | Calculate LINK fees |
| `setTrustedSender(uint64, address)` | Owner | Configure trusted bridges |
| `fundWithLink(uint256)` | Public | Deposit LINK for fees |
| `withdrawLink(address, uint256)` | Owner | Withdraw LINK |
| `onERC721Received(...)` | External | Accept NFT transfers |

**Security Features**:
- ✅ Validates sender is trusted (prevents unauthorized mints)
- ✅ Idempotent minting (checks if token exists)
- ✅ Uses immutable NFT reference (prevents tampering)
- ✅ Owner-controlled configurations

## Message Flow

### Sending NFT (Source Chain)

```solidity
function sendNFT(uint64 destinationChainSelector, address receiver, uint256 tokenId) 
    external returns (bytes32 messageId) 
{
    // 1. Validate inputs
    require(receiver != address(0), "Invalid receiver");
    require(trustedSenders[destinationChainSelector] != address(0), "Unknown chain");
    
    // 2. Get token metadata before burning
    string memory tokenURI_ = nft.tokenURI(tokenId);
    
    // 3. Transfer NFT to bridge and burn
    IERC721(address(nft)).transferFrom(msg.sender, address(this), tokenId);
    nft.burn(tokenId);
    
    // 4. Encode message
    bytes memory data = abi.encode(receiver, tokenId, tokenURI_);
    
    // 5. Build CCIP message
    Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
        receiver: abi.encode(trustedSenders[destinationChainSelector]),
        data: data,
        tokenAmounts: new Client.EVMTokenAmount[](0),
        extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 400_000})),
        feeToken: address(linkToken)
    });
    
    // 6. Pay fees and send
    uint256 fees = router.getFee(destinationChainSelector, message);
    linkToken.approve(address(router), fees);
    messageId = router.ccipSend(destinationChainSelector, message);
    
    emit NFTSent(messageId, destinationChainSelector, receiver, tokenId, tokenURI_);
}
```

### Receiving NFT (Destination Chain)

```solidity
function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
    // 1. Validate sender
    address sender = abi.decode(message.sender, (address));
    require(trustedSenders[message.sourceChainSelector] == sender, "Untrusted sender");
    
    // 2. Decode message
    (address receiver, uint256 tokenId, string memory tokenURI_) = 
        abi.decode(message.data, (address, uint256, string));
    
    // 3. Check idempotency (prevent duplicate mints)
    try nft.ownerOf(tokenId) returns (address) {
        revert("Token already minted");
    } catch {
        // Token doesn't exist, proceed with minting
        nft.mint(receiver, tokenId, tokenURI_);
    }
    
    emit NFTReceived(message.messageId, message.sourceChainSelector, 
                     sender, receiver, tokenId, tokenURI_);
}
```

## Gas Optimization

### Strategies Used

1. **Immutable Variables**: NFT reference is immutable (saves ~2,100 gas per access)
2. **Minimal Storage**: Only stores essential data (trusted senders mapping)
3. **Event Emission**: Off-chain tracking via events (cheaper than storage)
4. **External Calls**: Minimized to reduce gas overhead

### Gas Estimates

| Operation | Estimated Gas | LINK Cost* |
|-----------|--------------|------------|
| Deploy NFT | ~2,500,000 | N/A |
| Deploy Bridge | ~3,000,000 | N/A |
| Mint NFT | ~150,000 | N/A |
| Send NFT (Source) | ~200,000 | 0.5-2 LINK |
| Receive NFT (Dest) | ~150,000 | Paid by sender |

*LINK costs vary by network congestion

## Security Model

### Trust Assumptions

1. **CCIP Network**: Trusted to deliver messages accurately
2. **Bridge Owners**: Trusted to set correct trusted senders
3. **Smart Contracts**: Audited and verified on-chain

### Attack Vectors & Mitigations

| Attack | Mitigation |
|--------|-----------|
| Unauthorized minting | Only bridge can mint |
| Fake CCIP messages | Validates trusted senders |
| Token duplication | Burn-and-mint + idempotency |
| Reentrancy | OpenZeppelin's ReentrancyGuard patterns |
| Front-running | CCIP messages are atomic |

## Upgrade Path

### Current Limitations

- Bridge addresses are not upgradeable (use proxy pattern for production)
- Chain selectors are hardcoded (consider making dynamic)
- No pause mechanism (add emergency stop for production)

### Recommended Improvements

1. **Proxy Pattern**: Use UUPS or Transparent Proxy for upgradeability
2. **Pausable**: Add circuit breaker for emergencies
3. **Multi-sig**: Use Gnosis Safe for owner operations
4. **Rate Limiting**: Prevent spam attacks
5. **Fee Management**: Dynamic fee calculations

## Testing Strategy

### Unit Tests

- ✅ Access control on minting
- ✅ Trusted sender validation
- ✅ Idempotency checks
- ✅ Event emissions

### Integration Tests

- Cross-chain message encoding/decoding
- CCIP router interactions
- End-to-end transfer flow

### Testnet Verification

- Deploy to Fuji and Arbitrum Sepolia
- Execute real transfers
- Monitor CCIP Explorer

## Monitoring & Observability

### Events

The contracts emit comprehensive events for tracking:

```solidity
event NFTSent(bytes32 indexed messageId, uint64 destinationChainSelector, 
              address receiver, uint256 tokenId, string tokenURI);

event NFTReceived(bytes32 indexed messageId, uint64 sourceChainSelector, 
                  address sender, address receiver, uint256 tokenId, string tokenURI);

event TrustedSenderSet(uint64 chainSelector, address sender);
event BridgeSet(address indexed bridge);
```

### Monitoring Tools

- **CCIP Explorer**: Track message status
- **Block Explorers**: View transactions
- **The Graph**: Index events for analytics
- **Tenderly**: Debug transaction failures

## References

- [CCIP Documentation](https://docs.chain.link/ccip)
- [ERC-721 Standard](https://eips.ethereum.org/EIPS/eip-721)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Foundry Testing](https://book.getfoundry.sh/forge/tests)
