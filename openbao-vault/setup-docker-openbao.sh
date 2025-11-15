#!/bin/bash
# setup-docker-openbao.sh

echo "Setting up OpenBao in Docker container..."

CONTAINER_NAME="openbao-server-demo"

# Check if container exists and remove it
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

# Create data directory for persistence
mkdir -p ./vault-data
chmod 755 ./vault-data

# Create vault configuration
cat > vault-config.hcl << 'EOF'
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

ui = true
disable_mlock = true
EOF

# Start OpenBao container
docker run -d \
  --name $CONTAINER_NAME \
  --cap-add=IPC_LOCK \
  -p 8200:8200 \
  -v $(pwd)/vault-data:/vault/data \
  -v $(pwd)/vault-config.hcl:/vault/config/vault-config.hcl \
  openbao/openbao:latest \
  server -config=/vault/config/vault-config.hcl

echo "OpenBao container started. Waiting for startup..."
sleep 5

export VAULT_ADDR='http://127.0.0.1:8200'
echo "OpenBao is ready at $VAULT_ADDR"
