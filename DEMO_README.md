# OpenBao Setup Demo Guide

This guide demonstrates how to set up OpenBao for secret management in two deployment modes:
1. **Docker Container** - Isolated, portable deployment
2. **System Service** - Direct installation on host system

## Overview

OpenBao is a secrets management tool that securely stores and manages sensitive data like database credentials, API keys, and certificates. We'll demonstrate storing database credentials (`demo_db_user` and `demo_db_pwd`) as an example.

## Prerequisites

- Linux system with Docker (for container deployment)
- Root/sudo access (for service deployment)
- curl and jq utilities

## Deployment Option 1: Docker Container

### Step 1: Setup Docker Container

**What we do**: Create and configure OpenBao in a Docker container
**Why**: Provides isolation, easy cleanup, and consistent environment

```bash
#!/bin/bash
# setup-docker-openbao.sh

echo "Setting up OpenBao in Docker container..."

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
  --name vault-server \
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
```

### Step 2: Initialize OpenBao

**What we do**: Initialize the vault and generate unseal keys
**Why**: Sets up the master key and creates initial root token for authentication

```bash
#!/bin/bash
# init-docker-openbao.sh

export VAULT_ADDR='http://127.0.0.1:8200'

echo "Initializing OpenBao..."

# Initialize vault with 5 key shares, threshold of 3
vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > .vault-keys.json

echo "Vault initialized. Keys saved to .vault-keys.json"

# Extract unseal keys and root token
UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' .vault-keys.json)
UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' .vault-keys.json)
UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' .vault-keys.json)
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)

# Unseal the vault
echo "Unsealing vault..."
vault operator unseal $UNSEAL_KEY_1
vault operator unseal $UNSEAL_KEY_2
vault operator unseal $UNSEAL_KEY_3

echo "Vault unsealed successfully!"
echo "Root token: $ROOT_TOKEN"
```

### Step 3: Configure Authentication and Policies

**What we do**: Set up AppRole authentication and create policies
**Why**: Provides secure, programmatic access without using root token

```bash
#!/bin/bash
# configure-docker-auth.sh

export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN

echo "Configuring authentication and policies..."

# Enable KV secrets engine
vault secrets enable -path=secret kv-v2

# Enable AppRole authentication
vault auth enable approle

# Create policy for database access
cat > db-policy.hcl << 'EOF'
path "secret/data/database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

vault policy write db-policy db-policy.hcl

# Create AppRole for application
vault write auth/approle/role/db-app \
  token_policies="db-policy" \
  token_ttl=1h \
  token_max_ttl=4h

# Get role credentials
ROLE_ID=$(vault read -field=role_id auth/approle/role/db-app/role-id)
SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/db-app/secret-id)

echo "Role ID: $ROLE_ID"
echo "Secret ID: $SECRET_ID"

# Save credentials
cat > .app-credentials << EOF
ROLE_ID=$ROLE_ID
SECRET_ID=$SECRET_ID
EOF

echo "Authentication configured successfully!"
```

### Step 4: Store Demo Database Secrets

**What we do**: Store database credentials in OpenBao
**Why**: Centralizes secret management and provides audit trail

```bash
#!/bin/bash
# store-demo-secrets.sh

export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)
export VAULT_TOKEN=$ROOT_TOKEN

echo "Storing demo database secrets..."

# Store database credentials
vault kv put secret/database/demo \
  username="demo_db_user" \
  password="demo_db_pwd"

echo "Demo secrets stored at secret/database/demo"

# Verify storage
echo "Verifying stored secrets:"
vault kv get secret/database/demo
```

### Step 5: Application Access Demo

**What we do**: Demonstrate how applications retrieve secrets
**Why**: Shows the complete workflow for secret consumption

```bash
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
```

### Step 6: Container Management

**What we do**: Provide utilities for container lifecycle management
**Why**: Simplifies daily operations and maintenance

```bash
#!/bin/bash
# manage-docker-vault.sh

CONTAINER_NAME="vault-server"

case "$1" in
  start)
    echo "Starting OpenBao container..."
    docker start $CONTAINER_NAME
    sleep 3
    
    # Auto-unseal if keys exist
    if [ -f .vault-keys.json ]; then
      export VAULT_ADDR='http://127.0.0.1:8200'
      UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' .vault-keys.json)
      UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' .vault-keys.json)
      UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' .vault-keys.json)
      
      vault operator unseal $UNSEAL_KEY_1
      vault operator unseal $UNSEAL_KEY_2
      vault operator unseal $UNSEAL_KEY_3
      echo "Vault unsealed and ready!"
    fi
    ;;
  stop)
    echo "Stopping OpenBao container..."
    docker stop $CONTAINER_NAME
    ;;
  status)
    docker ps -f name=$CONTAINER_NAME
    ;;
  logs)
    docker logs $CONTAINER_NAME
    ;;
  *)
    echo "Usage: $0 {start|stop|status|logs}"
    exit 1
    ;;
esac
```

## Deployment Option 2: System Service

### Step 1: Install OpenBao as Service

**What we do**: Install OpenBao directly on the host system
**Why**: Better performance, system integration, and resource utilization

```bash
#!/bin/bash
# install-service-openbao.sh

echo "Installing OpenBao as system service..."

# Create vault user
sudo useradd --system --home /etc/vault.d --shell /bin/false vault

# Create directories
sudo mkdir -p /opt/vault/data
sudo mkdir -p /etc/vault.d
sudo chown -R vault:vault /opt/vault
sudo chown -R vault:vault /etc/vault.d

# Download and install OpenBao
VAULT_VERSION="2.0.0"
cd /tmp
wget https://github.com/openbao/openbao/releases/download/v${VAULT_VERSION}/bao_${VAULT_VERSION}_linux_amd64.zip
unzip bao_${VAULT_VERSION}_linux_amd64.zip
sudo mv bao /usr/local/bin/
sudo chmod +x /usr/local/bin/bao

# Create configuration
sudo tee /etc/vault.d/vault.hcl > /dev/null << 'EOF'
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = true
}

ui = true
disable_mlock = true
EOF

# Create systemd service
sudo tee /etc/systemd/system/vault.service > /dev/null << 'EOF'
[Unit]
Description=OpenBao
Documentation=https://openbao.org/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
Type=notify
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/bao server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
KillSignal=SIGINT
TimeoutStopSec=30s
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

echo "OpenBao service installed and started"
echo "Status: $(sudo systemctl is-active vault)"
```

### Step 2: Initialize Service-based OpenBao

**What we do**: Initialize the service installation
**Why**: Same as Docker but adapted for service deployment

```bash
#!/bin/bash
# init-service-openbao.sh

export VAULT_ADDR='http://127.0.0.1:8200'

echo "Waiting for OpenBao service to be ready..."
sleep 5

echo "Initializing OpenBao service..."

# Initialize vault
bao operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > /home/$USER/.vault-keys.json

chmod 600 /home/$USER/.vault-keys.json

# Extract and unseal
UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' /home/$USER/.vault-keys.json)
UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' /home/$USER/.vault-keys.json)
UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' /home/$USER/.vault-keys.json)

bao operator unseal $UNSEAL_KEY_1
bao operator unseal $UNSEAL_KEY_2
bao operator unseal $UNSEAL_KEY_3

echo "Service-based OpenBao initialized and unsealed!"
```

### Step 3: Service Management

**What we do**: Provide service management utilities
**Why**: Integrates with systemd for proper service lifecycle management

```bash
#!/bin/bash
# manage-service-vault.sh

case "$1" in
  start)
    echo "Starting OpenBao service..."
    sudo systemctl start vault
    sleep 3
    
    # Auto-unseal if keys exist
    if [ -f /home/$USER/.vault-keys.json ]; then
      export VAULT_ADDR='http://127.0.0.1:8200'
      UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' /home/$USER/.vault-keys.json)
      UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' /home/$USER/.vault-keys.json)
      UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' /home/$USER/.vault-keys.json)
      
      bao operator unseal $UNSEAL_KEY_1
      bao operator unseal $UNSEAL_KEY_2
      bao operator unseal $UNSEAL_KEY_3
      echo "Service unsealed and ready!"
    fi
    ;;
  stop)
    echo "Stopping OpenBao service..."
    sudo systemctl stop vault
    ;;
  restart)
    echo "Restarting OpenBao service..."
    sudo systemctl restart vault
    ;;
  status)
    sudo systemctl status vault
    ;;
  logs)
    sudo journalctl -u vault -f
    ;;
  enable)
    sudo systemctl enable vault
    echo "OpenBao service enabled for auto-start"
    ;;
  disable)
    sudo systemctl disable vault
    echo "OpenBao service disabled from auto-start"
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|logs|enable|disable}"
    exit 1
    ;;
esac
```

## Complete Setup Scripts

### Docker Complete Setup

```bash
#!/bin/bash
# complete-docker-setup.sh

echo "=== Complete OpenBao Docker Setup ==="

# Step 1: Setup container
./setup-docker-openbao.sh

# Step 2: Initialize
./init-docker-openbao.sh

# Step 3: Configure auth
./configure-docker-auth.sh

# Step 4: Store demo secrets
./store-demo-secrets.sh

echo "=== Setup Complete ==="
echo "OpenBao UI: http://127.0.0.1:8200"
echo "Demo secrets stored at: secret/database/demo"
echo "Use ./app-access-demo.sh to test secret retrieval"
echo "Use ./manage-docker-vault.sh for daily operations"
```

### Service Complete Setup

```bash
#!/bin/bash
# complete-service-setup.sh

echo "=== Complete OpenBao Service Setup ==="

# Step 1: Install service
./install-service-openbao.sh

# Step 2: Initialize
./init-service-openbao.sh

# Step 3: Configure (reuse Docker script with bao command)
sed 's/vault/bao/g' configure-docker-auth.sh > configure-service-auth.sh
chmod +x configure-service-auth.sh
./configure-service-auth.sh

# Step 4: Store secrets (reuse Docker script with bao command)
sed 's/vault/bao/g' store-demo-secrets.sh > store-service-secrets.sh
chmod +x store-service-secrets.sh
./store-service-secrets.sh

echo "=== Setup Complete ==="
echo "OpenBao UI: http://127.0.0.1:8200"
echo "Service status: $(sudo systemctl is-active vault)"
echo "Use ./manage-service-vault.sh for daily operations"
```

## Key Differences: Docker vs Service

| Aspect | Docker | Service |
|--------|--------|---------|
| **Installation** | Container-based, isolated | Direct system installation |
| **Performance** | Slight overhead | Native performance |
| **Persistence** | Volume mounts required | Direct filesystem access |
| **Management** | Docker commands | systemd commands |
| **Resource Usage** | Container overhead | Direct system resources |
| **Backup** | Volume backup | Directory backup |
| **Updates** | New container image | Binary replacement |
| **Integration** | Port mapping needed | Direct system integration |

## Security Considerations

1. **File Permissions**: Ensure `.vault-keys.json` and `.app-credentials` have restricted permissions (600)
2. **Network Access**: Consider firewall rules for port 8200
3. **TLS**: Enable TLS in production environments
4. **Key Management**: Store unseal keys securely and separately
5. **Audit Logging**: Enable audit logs for compliance
6. **Regular Rotation**: Implement secret rotation policies

## Troubleshooting

### Common Issues

1. **Port Already in Use**: Change port in configuration or stop conflicting service
2. **Permission Denied**: Check file/directory permissions and user ownership
3. **Vault Sealed**: Run unseal commands with proper keys
4. **Connection Refused**: Verify service is running and listening on correct port

### Useful Commands

```bash
# Check vault status
vault status

# List enabled auth methods
vault auth list

# List policies
vault policy list

# Check token info
vault token lookup

# Seal vault (emergency)
vault operator seal
```

This demo provides a complete foundation for OpenBao deployment and management in both containerized and service environments.
