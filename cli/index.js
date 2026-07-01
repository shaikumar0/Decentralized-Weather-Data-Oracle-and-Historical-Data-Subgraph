const ethers = require('ethers');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

// Chain configurations
const CHAINS = {
  'avalanche-fuji': {
    name: 'Avalanche Fuji',
    rpcUrl: process.env.FUJI_RPC_URL,
    chainSelector: '14767482510784806043',
    nftAddress: null,
    bridgeAddress: null,
  },
  'arbitrum-sepolia': {
    name: 'Arbitrum Sepolia',
    rpcUrl: process.env.ARBITRUM_SEPOLIA_RPC_URL,
    chainSelector: '3478487238524512106',
    nftAddress: null,
    bridgeAddress: null,
  },
};

// Load deployment addresses
function loadDeploymentAddresses() {
  try {
    const deploymentPath = path.join(__dirname, '..', 'deployment.json');
    const deployment = JSON.parse(fs.readFileSync(deploymentPath, 'utf8'));

    CHAINS['avalanche-fuji'].nftAddress = deployment.avalancheFuji.nftContractAddress;
    CHAINS['avalanche-fuji'].bridgeAddress = deployment.avalancheFuji.bridgeContractAddress;
    CHAINS['arbitrum-sepolia'].nftAddress = deployment.arbitrumSepolia.nftContractAddress;
    CHAINS['arbitrum-sepolia'].bridgeAddress = deployment.arbitrumSepolia.bridgeContractAddress;
  } catch (error) {
    console.error('Error loading deployment addresses:', error.message);
    process.exit(1);
  }
}

// Load contract ABIs
function loadABI(contractName) {
  try {
    const abiPath = path.join(__dirname, '..', 'out', `${contractName}.sol`, `${contractName}.json`);
    const artifact = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
    return artifact.abi;
  } catch (error) {
    console.error(`Error loading ABI for ${contractName}:`, error.message);
    process.exit(1);
  }
}

// Logger function
function log(message, level = 'INFO') {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${level}] ${message}\n`;

  // Log to console
  console.log(logMessage.trim());

  // Append to log file
  const logDir = path.join(__dirname, '..', 'logs');
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }

  const logPath = path.join(logDir, 'transfers.log');
  fs.appendFileSync(logPath, logMessage);
}

// Save transfer record to JSON file
function saveTransferRecord(record) {
  const dataDir = path.join(__dirname, '..', 'data');
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }

  const dataPath = path.join(dataDir, 'nft_transfers.json');
  let transfers = [];

  // Load existing transfers
  if (fs.existsSync(dataPath)) {
    try {
      transfers = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
      if (!Array.isArray(transfers)) {
        transfers = [];
      }
    } catch (error) {
      log(`Warning: Could not parse existing transfers file. Starting fresh.`, 'WARN');
      transfers = [];
    }
  }

  // Add new transfer
  transfers.push(record);

  // Save back to file
  fs.writeFileSync(dataPath, JSON.stringify(transfers, null, 2));
  log(`Transfer record saved to ${dataPath}`);
}

// Parse command line arguments
function parseArguments() {
  const args = process.argv.slice(2);
  const params = {};

  args.forEach((arg) => {
    if (arg.startsWith('--')) {
      const [key, value] = arg.substring(2).split('=');
      params[key] = value;
    }
  });

  // Validate required parameters
  const required = ['tokenId', 'from', 'to', 'receiver'];
  for (const param of required) {
    if (!params[param]) {
      console.error(`Error: Missing required parameter --${param}`);
      console.log('\nUsage: npm run transfer -- --tokenId=<id> --from=<chain> --to=<chain> --receiver=<address>');
      console.log('\nExample: npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb');
      process.exit(1);
    }
  }

  // Validate chains
  if (!CHAINS[params.from]) {
    console.error(`Error: Invalid source chain '${params.from}'. Must be 'avalanche-fuji' or 'arbitrum-sepolia'`);
    process.exit(1);
  }

  if (!CHAINS[params.to]) {
    console.error(`Error: Invalid destination chain '${params.to}'. Must be 'avalanche-fuji' or 'arbitrum-sepolia'`);
    process.exit(1);
  }

  if (params.from === params.to) {
    console.error('Error: Source and destination chains must be different');
    process.exit(1);
  }

  // Validate receiver address
  if (!ethers.isAddress(params.receiver)) {
    console.error(`Error: Invalid receiver address '${params.receiver}'`);
    process.exit(1);
  }

  return params;
}

// Main transfer function
async function transferNFT() {
  try {
    log('=== Starting Cross-Chain NFT Transfer ===');

    // Parse arguments
    const params = parseArguments();
    log(`Parameters: tokenId=${params.tokenId}, from=${params.from}, to=${params.to}, receiver=${params.receiver}`);

    // Load deployment addresses
    loadDeploymentAddresses();

    // Get chain configurations
    const sourceChain = CHAINS[params.from];
    const destChain = CHAINS[params.to];

    log(`Source Chain: ${sourceChain.name}`);
    log(`Destination Chain: ${destChain.name}`);

    // Set up provider and signer
    const provider = new ethers.JsonRpcProvider(sourceChain.rpcUrl);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    log(`Using wallet address: ${wallet.address}`);

    // Load contract ABIs
    const nftABI = loadABI('CrossChainNFT');
    const bridgeABI = loadABI('CCIPNFTBridge');

    // Connect to contracts
    const nftContract = new ethers.Contract(sourceChain.nftAddress, nftABI, wallet);
    const bridgeContract = new ethers.Contract(sourceChain.bridgeAddress, bridgeABI, wallet);

    // Verify NFT ownership
    log(`Verifying NFT ownership for token ID ${params.tokenId}...`);
    const owner = await nftContract.ownerOf(params.tokenId);
    if (owner.toLowerCase() !== wallet.address.toLowerCase()) {
      throw new Error(`Token ${params.tokenId} is not owned by ${wallet.address}. Current owner: ${owner}`);
    }
    log(`Ownership verified. Current owner: ${owner}`);

    // Get token URI
    const tokenURI = await nftContract.tokenURI(params.tokenId);
    log(`Token URI: ${tokenURI}`);

    // Fetch metadata if it's an HTTP/HTTPS URL
    let metadata = null;
    if (tokenURI.startsWith('http://') || tokenURI.startsWith('https://')) {
      try {
        const response = await fetch(tokenURI);
        metadata = await response.json();
        log(`Metadata fetched: ${JSON.stringify(metadata)}`);
      } catch (error) {
        log(`Could not fetch metadata from URI: ${error.message}`, 'WARN');
      }
    }

    // Estimate transfer cost
    log('Estimating transfer cost...');
    const estimatedCost = await bridgeContract.estimateTransferCost(destChain.chainSelector);
    log(`Estimated cost: ${ethers.formatEther(estimatedCost)} LINK`);

    // Check LINK balance
    const linkBalance = await provider.getBalance(bridgeContract.target);
    log(`Bridge LINK balance: ${ethers.formatEther(linkBalance)} LINK`);

    // Approve NFT for bridge if not already approved
    log('Checking NFT approval...');
    const approved = await nftContract.getApproved(params.tokenId);
    if (approved.toLowerCase() !== bridgeContract.target.toLowerCase()) {
      log('Approving bridge to transfer NFT...');
      const approveTx = await nftContract.approve(bridgeContract.target, params.tokenId);
      log(`Approval transaction sent: ${approveTx.hash}`);
      await approveTx.wait();
      log('Approval confirmed');
    } else {
      log('Bridge already approved for this token');
    }

    // Send NFT
    log('Initiating cross-chain transfer...');
    const tx = await bridgeContract.sendNFT(
      destChain.chainSelector,
      params.receiver,
      params.tokenId
    );

    log(`Transaction sent: ${tx.hash}`);
    log('Waiting for confirmation...');

    const receipt = await tx.wait();
    log(`Transaction confirmed in block ${receipt.blockNumber}`);

    // Extract CCIP message ID from events
    let ccipMessageId = null;
    for (const log of receipt.logs) {
      try {
        const parsedLog = bridgeContract.interface.parseLog(log);
        if (parsedLog && parsedLog.name === 'NFTSent') {
          ccipMessageId = parsedLog.args.messageId;
          log(`CCIP Message ID: ${ccipMessageId}`);
          break;
        }
      } catch (error) {
        // Not a bridge log, continue
      }
    }

    // Create transfer record
    const transferRecord = {
      transferId: uuidv4(),
      tokenId: params.tokenId.toString(),
      sourceChain: params.from,
      destinationChain: params.to,
      sender: wallet.address,
      receiver: params.receiver,
      ccipMessageId: ccipMessageId || 'N/A',
      sourceTxHash: tx.hash,
      destinationTxHash: null,
      status: 'initiated',
      metadata: metadata || {
        name: `Token #${params.tokenId}`,
        description: 'Cross-chain NFT',
        image: tokenURI,
      },
      timestamp: new Date().toISOString(),
    };

    // Save transfer record
    saveTransferRecord(transferRecord);

    log('=== Transfer Initiated Successfully ===');
    log(`Track your transfer on CCIP Explorer: https://ccip.chain.link/msg/${ccipMessageId}`);
    log(`The NFT will appear on ${destChain.name} once the CCIP message is processed (typically 5-10 minutes)`);

    return transferRecord;
  } catch (error) {
    log(`Error during transfer: ${error.message}`, 'ERROR');
    if (error.stack) {
      log(error.stack, 'ERROR');
    }
    throw error;
  }
}

// Run the transfer
if (require.main === module) {
  transferNFT()
    .then(() => {
      process.exit(0);
    })
    .catch((error) => {
      console.error('Transfer failed:', error.message);
      process.exit(1);
    });
}

module.exports = { transferNFT };
