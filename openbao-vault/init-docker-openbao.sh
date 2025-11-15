#!/bin/bash
# init-docker-openbao.sh

export VAULT_ADDR='http://127.0.0.1:8200'
CONTAINER_NAME="openbao-server-demo"

echo "Initializing OpenBao..."

# Check if container is running
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Error: $CONTAINER_NAME container is not running. Run ./setup-docker-openbao.sh first"
    exit 1
fi

# Wait for OpenBao to be ready
echo "Waiting for OpenBao to be ready..."
sleep 5

# Initialize vault with 5 key shares, threshold of 3
echo "Running initialization..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > .vault-keys.json

# Check if initialization was successful
if [ ! -s .vault-keys.json ]; then
    echo "Error: Initialization failed or vault already initialized"
    echo "Checking vault status..."
    docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao status
    exit 1
fi

echo "Vault initialized. Keys saved to .vault-keys.json"

# Extract unseal keys and root token
UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' .vault-keys.json)
UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' .vault-keys.json)
UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' .vault-keys.json)
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)

echo "Extracted keys successfully"
echo "Root token: $ROOT_TOKEN"

# Unseal the vault
echo "Unsealing vault..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_1
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_2
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_3

echo "Vault unsealed successfully!"
echo "Keys and root token saved to .vault-keys.json"

# Display the contents for verification
echo "=== Vault Keys File Contents ==="
cat .vault-keys.json | jq .
