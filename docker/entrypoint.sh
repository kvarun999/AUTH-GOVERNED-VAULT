#!/bin/sh

# Start Anvil in the background
anvil --host 0.0.0.0 &

# Wait for Anvil to be ready
echo "Waiting for local node..."
sleep 5

# Set the standard Anvil private key
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

echo "Starting deployment script..."
forge script script/Deploy.s.sol:DeploySystem --rpc-url http://127.0.0.1:8545 --broadcast

echo "--- DEPLOYMENT FINISHED ---"

# Keep the container alive
wait