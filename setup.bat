@echo off
REM Colors not supported in basic Windows CMD, but we'll make it work

echo ==================================
echo CCIP NFT Bridge Setup Script
echo ==================================
echo.

REM Check if .env exists
if not exist .env (
    echo Error: .env file not found!
    echo Please copy .env.example to .env and configure it:
    echo   copy .env.example .env
    exit /b 1
)

echo [OK] Found .env file

REM Load environment variables from .env
for /f "delims=" %%a in (.env) do (
    set "%%a"
)

REM Check if PRIVATE_KEY is set
if "%PRIVATE_KEY%"=="your_private_key_here" (
    echo Error: PRIVATE_KEY not configured in .env
    exit /b 1
)

echo [OK] Environment variables loaded
echo.

REM Install Foundry dependencies
echo Installing Foundry dependencies...
call forge install OpenZeppelin/openzeppelin-contracts --no-commit
call forge install smartcontractkit/ccip --no-commit
call forge install smartcontractkit/chainlink-brownie-contracts --no-commit
echo [OK] Foundry dependencies installed
echo.

REM Install Node.js dependencies
echo Installing Node.js dependencies...
call npm install
echo [OK] Node.js dependencies installed
echo.

REM Compile contracts
echo Compiling smart contracts...
call forge build
if errorlevel 1 (
    echo Error: Contract compilation failed
    exit /b 1
)
echo [OK] Contracts compiled successfully
echo.

REM Deploy to Avalanche Fuji
echo Deploying to Avalanche Fuji...
set NETWORK=fuji
call forge script script/Deploy.s.sol:Deploy --rpc-url %FUJI_RPC_URL% --broadcast
if errorlevel 1 (
    echo Error: Deployment to Fuji failed
    exit /b 1
)
echo [OK] Deployed to Avalanche Fuji
echo.

echo Please update deployment.json with the Fuji contract addresses shown above.
pause

REM Deploy to Arbitrum Sepolia
echo Deploying to Arbitrum Sepolia...
set NETWORK=arbitrum-sepolia
call forge script script/Deploy.s.sol:Deploy --rpc-url %ARBITRUM_SEPOLIA_RPC_URL% --broadcast
if errorlevel 1 (
    echo Error: Deployment to Arbitrum Sepolia failed
    exit /b 1
)
echo [OK] Deployed to Arbitrum Sepolia
echo.

echo Please update deployment.json with the Arbitrum Sepolia contract addresses.
echo Also update the .env file with all deployed addresses.
pause

REM Configure bridges
echo Configuring Fuji bridge...
set NETWORK=fuji
call forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url %FUJI_RPC_URL% --broadcast
echo [OK] Fuji bridge configured
echo.

echo Configuring Arbitrum Sepolia bridge...
set NETWORK=arbitrum-sepolia
call forge script script/ConfigureBridge.s.sol:ConfigureBridge --rpc-url %ARBITRUM_SEPOLIA_RPC_URL% --broadcast
echo [OK] Arbitrum Sepolia bridge configured
echo.

REM Mint test NFT
echo Minting test NFT on Avalanche Fuji...
set NETWORK=fuji
call forge script script/MintTestNFT.s.sol:MintTestNFT --rpc-url %FUJI_RPC_URL% --broadcast
echo [OK] Test NFT minted
echo.

echo ==================================
echo Setup Complete!
echo ==================================
echo.

echo Next steps:
echo 1. Fund both bridge contracts with LINK tokens
echo 2. Build the Docker container: docker-compose up -d
echo 3. Transfer an NFT: docker exec ccip-nft-bridge-cli npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=^<address^>
echo.
echo Happy bridging!
echo.

pause
