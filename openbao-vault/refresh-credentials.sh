#!/bin/bash
# refresh-credentials.sh - Refresh application credentials

export VAULT_ADDR='http://127.0.0.1:8200'
CONTAINER_NAME="openbao-server-demo"

echo "🔄 REFRESHING APPLICATION CREDENTIALS"
echo "======================================"

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

ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN

echo "🎫 Generating fresh Flask application credentials..."
FLASK_ROLE_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/flask-app-role/role-id 2>/dev/null || echo "")
FLASK_SECRET_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/flask-app-role/secret-id 2>/dev/null || echo "")

echo "🎫 Generating fresh Spring Boot application credentials..."
SPRINGBOOT_ROLE_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/springboot-app-role/role-id 2>/dev/null || echo "")
SPRINGBOOT_SECRET_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/springboot-app-role/secret-id 2>/dev/null || echo "")

if [ ! -z "$FLASK_ROLE_ID" ] && [ ! -z "$FLASK_SECRET_ID" ] && [ ! -z "$SPRINGBOOT_ROLE_ID" ] && [ ! -z "$SPRINGBOOT_SECRET_ID" ]; then
    # Remove old credentials file
    rm -f .app-credentials
    
    # Create fresh credentials file
    cat > .app-credentials << EOF
# Flask Application Credentials
FLASK_ROLE_ID=$FLASK_ROLE_ID
FLASK_SECRET_ID=$FLASK_SECRET_ID

# Spring Boot Application Credentials
SPRINGBOOT_ROLE_ID=$SPRINGBOOT_ROLE_ID
SPRINGBOOT_SECRET_ID=$SPRINGBOOT_SECRET_ID
EOF
    echo "✅ Fresh credentials saved to '.app-credentials'"
    echo "   Flask Role ID: ${FLASK_ROLE_ID:0:8}..."
    echo "   Spring Boot Role ID: ${SPRINGBOOT_ROLE_ID:0:8}..."
    echo ""
    echo "🚀 Applications can now use the refreshed credentials!"
else
    echo "❌ Error: Could not generate fresh credentials"
    echo "💡 Check if AppRoles exist: ./configure-docker-auth.sh"
fi
