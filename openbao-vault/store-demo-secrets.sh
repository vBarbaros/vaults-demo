#!/bin/bash
# store-demo-secrets.sh

export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN

echo "Storing demo database secrets..."

# Store database credentials
docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao kv put secret/database/demo \
  username="demo_db_user" \
  password="demo_db_pwd"

echo "Demo secrets stored at secret/database/demo"

# Verify storage
echo "Verifying stored secrets:"
docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao kv get secret/database/demo
