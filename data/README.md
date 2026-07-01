# Example NFT Transfers JSON Structure

This file shows the structure of the `nft_transfers.json` file that gets generated after executing transfers.

```json
[
  {
    "transferId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "tokenId": "1",
    "sourceChain": "avalanche-fuji",
    "destinationChain": "arbitrum-sepolia",
    "sender": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "receiver": "0x9876543210aBcDeF0123456789AbCdEf01234567",
    "ccipMessageId": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    "sourceTxHash": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
    "destinationTxHash": null,
    "status": "initiated",
    "metadata": {
      "name": "Cool NFT #1",
      "description": "A cross-chain NFT demonstrating CCIP functionality",
      "image": "ipfs://QmY7Mhyj3vX5p9KqF2zFvN8gW4xR7jH2nP9sL5kM6tQ8wZ"
    },
    "timestamp": "2026-02-22T10:30:00.000Z"
  },
  {
    "transferId": "b2c3d4e5-f6g7-8901-bcde-fg2345678901",
    "tokenId": "2",
    "sourceChain": "arbitrum-sepolia",
    "destinationChain": "avalanche-fuji",
    "sender": "0x9876543210aBcDeF0123456789AbCdEf01234567",
    "receiver": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "ccipMessageId": "0x2345678901bcdef2345678901bcdef2345678901bcdef2345678901bcdef234",
    "sourceTxHash": "0xbcdef2345678901bcdef2345678901bcdef2345678901bcdef2345678901bcd",
    "destinationTxHash": "0xcdef3456789012cdef3456789012cdef3456789012cdef3456789012cdef345",
    "status": "completed",
    "metadata": {
      "name": "Awesome NFT #2",
      "description": "Another cross-chain NFT",
      "image": "ipfs://QmZ8Nih4wW6q0r3Gx5NyR8jI3oQ0tM7lN8pK9uJ1vH2xY"
    },
    "timestamp": "2026-02-22T11:45:00.000Z"
  }
]
```

## Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `transferId` | string (UUID) | Unique identifier for the transfer |
| `tokenId` | string | The NFT token ID being transferred |
| `sourceChain` | string | Source blockchain (`avalanche-fuji` or `arbitrum-sepolia`) |
| `destinationChain` | string | Destination blockchain |
| `sender` | string (address) | Ethereum address of the sender |
| `receiver` | string (address) | Ethereum address of the receiver |
| `ccipMessageId` | string (bytes32) | CCIP message ID for tracking |
| `sourceTxHash` | string (hash) | Transaction hash on source chain |
| `destinationTxHash` | string (hash) or null | Transaction hash on destination chain (null until processed) |
| `status` | enum | Transfer status: `initiated`, `in-progress`, `completed`, or `failed` |
| `metadata` | object | NFT metadata object |
| `metadata.name` | string | Name of the NFT |
| `metadata.description` | string | Description of the NFT |
| `metadata.image` | string (URL) | Image URL (IPFS, HTTP, etc.) |
| `timestamp` | string (ISO-8601) | Timestamp when transfer was initiated |

## Status Values

- **initiated**: Transfer transaction sent on source chain
- **in-progress**: CCIP message is being processed
- **completed**: NFT successfully minted on destination chain
- **failed**: Transfer failed (e.g., insufficient LINK, validation error)

## Tracking Transfers

You can track transfers using:

1. **CCIP Explorer**: `https://ccip.chain.link/msg/{ccipMessageId}`
2. **Source Chain Explorer**: Search for `sourceTxHash`
3. **Destination Chain Explorer**: Search for `destinationTxHash` (when available)

## Programmatic Access

```javascript
const fs = require('fs');
const transfers = JSON.parse(fs.readFileSync('./data/nft_transfers.json', 'utf8'));

// Find a specific transfer
const transfer = transfers.find(t => t.transferId === 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');

// Filter by status
const completedTransfers = transfers.filter(t => t.status === 'completed');

// Get recent transfers
const recentTransfers = transfers
  .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
  .slice(0, 10);
```

## Notes

- This file is automatically created and updated by the CLI tool
- Each transfer appends a new entry to the array
- The file persists across container restarts when using volume mounts
- For production, consider using a database instead of JSON files
