#!/bin/bash
# app-access-demo.sh

export VAULT_ADDR='http://127.0.0.1:8200'

# Load app credentials
if [ -f .app-credentials ]; then
    source .app-credentials
    # Use Flask credentials for demo
    ROLE_ID=$FLASK_ROLE_ID
    SECRET_ID=$FLASK_SECRET_ID
else
    echo "Error: .app-credentials file not found. Run setup first."
    exit 1
fi

echo "Demonstrating application access to secrets using Flask credentials..."
echo "Role ID: ${ROLE_ID:0:8}..."

# Authenticate with AppRole
AUTH_RESPONSE=$(curl -s -X POST \
  -d "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
  $VAULT_ADDR/v1/auth/approle/login)

APP_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.auth.client_token')

if [ "$APP_TOKEN" = "null" ] || [ -z "$APP_TOKEN" ]; then
    echo "Error: Authentication failed"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo "Authentication successful! Token: ${APP_TOKEN:0:8}..."

# Retrieve database secrets
DB_SECRETS=$(curl -s -H "X-Vault-Token: $APP_TOKEN" \
  $VAULT_ADDR/v1/secret/data/database/demo)

DB_USER=$(echo $DB_SECRETS | jq -r '.data.data.username')
DB_PASS=$(echo $DB_SECRETS | jq -r '.data.data.password')

echo "Retrieved credentials:"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
