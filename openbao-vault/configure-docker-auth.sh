#!/bin/bash
# configure-docker-auth.sh

export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN

echo "Configuring authentication and policies..."

# Enable KV secrets engine
docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao secrets enable -path=secret kv-v2

# Enable AppRole authentication
docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao auth enable approle

# Create policy for database access
cat > db-policy.hcl << 'EOF'
path "secret/data/database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

docker cp db-policy.hcl vault-server:/tmp/db-policy.hcl
docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao policy write db-policy /tmp/db-policy.hcl

# Create AppRole for application
docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao write auth/approle/role/db-app \
  token_policies="db-policy" \
  token_ttl=1h \
  token_max_ttl=4h

# Get role credentials
ROLE_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao read -field=role_id auth/approle/role/db-app/role-id)
SECRET_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN vault-server bao write -field=secret_id -f auth/approle/role/db-app/secret-id)

echo "Role ID: $ROLE_ID"
echo "Secret ID: $SECRET_ID"

# Save credentials
cat > .app-credentials << EOF
ROLE_ID=$ROLE_ID
SECRET_ID=$SECRET_ID
EOF

echo "Authentication configured successfully!"
