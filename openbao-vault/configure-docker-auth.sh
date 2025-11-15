#!/bin/bash
# configure-docker-auth.sh

export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN
CONTAINER_NAME="openbao-server-demo"

echo "Configuring authentication and policies..."

# Enable KV secrets engine
docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao secrets enable -path=secret kv-v2 2>/dev/null || true

# Enable AppRole authentication
docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao auth enable approle 2>/dev/null || true

# Create policy for database access
cat > db-policy.hcl << 'EOF'
path "secret/data/database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

docker cp db-policy.hcl $CONTAINER_NAME:/tmp/db-policy.hcl
docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao policy write db-policy /tmp/db-policy.hcl 2>/dev/null || true

# Create Flask AppRole
docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write auth/approle/role/flask-app-role \
  token_policies="db-policy" \
  token_ttl=1h \
  token_max_ttl=4h 2>/dev/null || true

# Create Spring Boot AppRole  
docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write auth/approle/role/springboot-app-role \
  token_policies="db-policy" \
  token_ttl=1h \
  token_max_ttl=4h 2>/dev/null || true

# Get Flask credentials
FLASK_ROLE_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/flask-app-role/role-id 2>/dev/null || echo "")
FLASK_SECRET_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/flask-app-role/secret-id 2>/dev/null || echo "")

# Get Spring Boot credentials
SPRINGBOOT_ROLE_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/springboot-app-role/role-id 2>/dev/null || echo "")
SPRINGBOOT_SECRET_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/springboot-app-role/secret-id 2>/dev/null || echo "")

echo "Flask Role ID: $FLASK_ROLE_ID"
echo "Flask Secret ID: $FLASK_SECRET_ID"
echo "Spring Boot Role ID: $SPRINGBOOT_ROLE_ID"
echo "Spring Boot Secret ID: $SPRINGBOOT_SECRET_ID"

# Save credentials
if [ ! -z "$FLASK_ROLE_ID" ] && [ ! -z "$FLASK_SECRET_ID" ] && [ ! -z "$SPRINGBOOT_ROLE_ID" ] && [ ! -z "$SPRINGBOOT_SECRET_ID" ]; then
    cat > .app-credentials << EOF
# Flask Application Credentials
FLASK_ROLE_ID=$FLASK_ROLE_ID
FLASK_SECRET_ID=$FLASK_SECRET_ID

# Spring Boot Application Credentials
SPRINGBOOT_ROLE_ID=$SPRINGBOOT_ROLE_ID
SPRINGBOOT_SECRET_ID=$SPRINGBOOT_SECRET_ID
EOF
    echo "Authentication configured successfully!"
    echo "Credentials saved to .app-credentials"
else
    echo "Warning: Could not generate all credentials"
fi
