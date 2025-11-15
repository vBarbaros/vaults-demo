#!/bin/bash
# app-access-demo.sh

export VAULT_ADDR='http://127.0.0.1:8200'

# Load app credentials
source .app-credentials

echo "Demonstrating application access to secrets..."

# Authenticate with AppRole
AUTH_RESPONSE=$(curl -s -X POST \
  -d "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
  $VAULT_ADDR/v1/auth/approle/login)

APP_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.auth.client_token')

# Retrieve database secrets
DB_SECRETS=$(curl -s -H "X-Vault-Token: $APP_TOKEN" \
  $VAULT_ADDR/v1/secret/data/database/demo)

DB_USER=$(echo $DB_SECRETS | jq -r '.data.data.username')
DB_PASS=$(echo $DB_SECRETS | jq -r '.data.data.password')

echo "Retrieved credentials:"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
