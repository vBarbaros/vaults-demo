#!/bin/bash
# store-demo-secrets.sh

export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN
CONTAINER_NAME="openbao-server-demo"

echo "Storing database secrets from db-credentials-in-use.json..."

# Check if credentials file exists
if [ ! -f "db-credentials-in-use.json" ]; then
    echo "Error: db-credentials-in-use.json not found"
    exit 1
fi

# Extract credentials from JSON file
DB_USERNAME=$(jq -r '.username' db-credentials-in-use.json)
DB_PASSWORD=$(jq -r '.password' db-credentials-in-use.json)

echo "Loading credentials from JSON file:"
echo "  Username: $DB_USERNAME"
echo "  Password: ${DB_PASSWORD:0:3}... (truncated)"

# Store database credentials in OpenBao
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao kv put secret/database/demo \
  username="$DB_USERNAME" \
  password="$DB_PASSWORD" 2>/dev/null || true

echo "Database secrets stored at secret/database/demo"

# Verify storage
echo "Verifying stored secrets:"
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao kv get secret/database/demo
