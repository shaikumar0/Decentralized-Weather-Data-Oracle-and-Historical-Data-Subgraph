// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CrossChainNFT
 * @notice ERC-721 NFT contract with access-controlled minting for cross-chain bridge
 * @dev Only the designated bridge contract can mint new NFTs
 */
contract CrossChainNFT is ERC721URIStorage, Ownable {
    address public bridge;

    event BridgeSet(address indexed bridge);

    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {}

    /**
     * @notice Modifier to restrict function access to only the bridge contract
     */
    modifier onlyBridge() {
        require(msg.sender == bridge, "Caller is not the bridge");
        _;
    }

    /**
     * @notice Set the bridge contract address
     * @param _bridge The address of the authorized bridge contract
     */
    function setBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Bridge address cannot be zero");
        bridge = _bridge;
        emit BridgeSet(_bridge);
    }

    /**
     * @notice Mint a new NFT with a specific token URI
     * @dev Only callable by the bridge contract
     * @param to The address to mint the NFT to
     * @param tokenId The ID of the token to mint
     * @param tokenURI_ The metadata URI for the token
     */
    function mint(address to, uint256 tokenId, string memory tokenURI_)
        external
        onlyBridge
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    /**
     * @notice Burn an existing NFT
     * @dev Only callable by the token owner or approved address
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) external {
        require(
            _isAuthorized(_ownerOf(tokenId), _msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    /**
     * @notice Check if an address is authorized to operate on a token
     * @param owner The owner of the token
     * @param spender The address to check authorization for
     * @param tokenId The ID of the token
     * @return bool Whether the spender is authorized
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        return (
            spender != address(0)
                && (owner == spender || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender)
        );
    }
}
