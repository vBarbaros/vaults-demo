#!/bin/bash
# update-credentials.sh - Update database credentials in OpenBao

export VAULT_ADDR='http://127.0.0.1:8200'
CONTAINER_NAME="openbao-server-demo"

echo "🔄 UPDATING DATABASE CREDENTIALS"
echo "================================="

# Check if vault keys exist
if [ ! -f .vault-keys.json ]; then
    echo "❌ Error: .vault-keys.json not found. Run setup first."
    exit 1
fi

# Check if container is running
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "❌ Error: $CONTAINER_NAME container is not running."
    echo "💡 Start with: ./manage-docker-vault.sh start"
    exit 1
fi

# Check if credentials file exists
if [ ! -f "db-credentials-in-use.json" ]; then
    echo "❌ Error: db-credentials-in-use.json not found."
    echo "💡 Create the file with your database credentials."
    exit 1
fi

ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN

echo "📋 Current credentials in db-credentials-in-use.json:"
jq . db-credentials-in-use.json

echo ""
read -p "🤔 Do you want to update these credentials in OpenBao? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 0
fi

# Extract credentials from JSON file
DB_USERNAME=$(jq -r '.username' db-credentials-in-use.json)
DB_PASSWORD=$(jq -r '.password' db-credentials-in-use.json)

echo "🔄 Updating OpenBao with new credentials..."
echo "   Username: $DB_USERNAME"
echo "   Password: ${DB_PASSWORD:0:3}... (truncated)"

# Update credentials in OpenBao
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao kv put secret/database/demo \
  username="$DB_USERNAME" \
  password="$DB_PASSWORD"

if [ $? -eq 0 ]; then
    echo "✅ Credentials updated successfully in OpenBao!"
    
    # Update timestamp in JSON file
    UPDATED_JSON=$(jq --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.last_updated = $timestamp' db-credentials-in-use.json)
    echo "$UPDATED_JSON" > db-credentials-in-use.json
    
    echo "📅 Updated timestamp in db-credentials-in-use.json"
    
    echo ""
    echo "🧪 Testing credential retrieval..."
    docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao kv get -field=username secret/database/demo
    
    echo ""
    echo "🚀 Applications will now receive the updated credentials!"
    echo "💡 Test with:"
    echo "   curl http://localhost:5000/db-credentials  # Flask app"
    echo "   curl http://localhost:8080/db-credentials  # Spring Boot app"
else
    echo "❌ Failed to update credentials in OpenBao"
fi
