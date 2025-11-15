#!/bin/bash
# complete-docker-setup.sh

echo "=========================================="
echo "    OpenBao Docker Setup Demo Script"
echo "=========================================="
echo "This script demonstrates how to set up OpenBao (open-source Vault) in Docker"
echo "for secrets management. We'll create a complete working environment with:"
echo "• Docker container running OpenBao server"
echo "• Initialization with unseal keys and root token"
echo "• AppRole (Application Role) authentication for applications"
echo "• Demo database credentials storage"
echo ""
echo "INFO: This educational script shows enterprise-grade secrets management setup."
echo "REASON: Understanding each step helps you implement secure secret storage in production."

# Check prerequisites
echo "🔍 CHECKING PREREQUISITES"
echo "----------------------------------------"
echo "For this demo to work, we need several tools installed:"
echo ""
echo "INFO: Prerequisites ensure all required tools are available before starting."
echo "REASON: Checking early prevents failures mid-setup and provides clear installation guidance."

# Check Docker
echo "1. Docker Engine - Container runtime for OpenBao"
if ! command -v docker &> /dev/null; then
    echo "   ❌ Docker is NOT installed"
    echo "   📋 Docker is required to run OpenBao in a container"
    echo "INFO: Docker provides isolated, portable environments for applications."
    echo "REASON: Containers ensure consistent OpenBao behavior across different systems."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   💡 Install with: brew install docker colima"
        echo "   💡 Or download Docker Desktop from: https://docker.com"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "   💡 Install with: sudo apt-get install docker.io (Ubuntu/Debian)"
        echo "   💡 Or: sudo yum install docker (RHEL/CentOS)"
    fi
    exit 1
else
    echo "   ✅ Docker is installed: $(docker --version)"
    echo "INFO: Docker engine is available for container operations."
    echo "REASON: This allows us to run OpenBao in an isolated, reproducible environment."
fi

# Check Docker daemon
echo ""
echo "2. Docker Daemon - Must be running to create containers"
if ! docker info &> /dev/null; then
    echo "   ❌ Docker daemon is NOT running"
    echo "   📋 The Docker service must be active to manage containers"
    echo "INFO: Docker daemon is the background service that manages containers."
    echo "REASON: Without the daemon, we cannot create, start, or manage Docker containers."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   💡 Start Docker Desktop application"
        echo "   💡 Or run: colima start (if using Colima)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "   💡 Start with: sudo systemctl start docker"
    fi
    exit 1
else
    echo "   ✅ Docker daemon is running"
    echo "INFO: Docker daemon is active and ready to manage containers."
    echo "REASON: This enables us to create and run the OpenBao container successfully."
fi

# Check jq
echo ""
echo "3. jq - JSON (JavaScript Object Notation) processor for parsing OpenBao responses"
if ! command -v jq &> /dev/null; then
    echo "   ❌ jq is NOT installed"
    echo "   📋 jq is needed to parse JSON responses from OpenBao API (Application Programming Interface)"
    echo "INFO: jq is a command-line JSON (JavaScript Object Notation) processor for extracting data from API responses."
    echo "REASON: OpenBao API (Application Programming Interface) returns JSON data; jq helps us extract keys, tokens, and secrets cleanly."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   💡 Install with: brew install jq"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "   💡 Install with: sudo apt-get install jq (Ubuntu/Debian)"
        echo "   💡 Or: sudo yum install jq (RHEL/CentOS)"
    fi
    exit 1
else
    echo "   ✅ jq is installed: $(jq --version)"
    echo "INFO: JSON (JavaScript Object Notation) processor is available for parsing OpenBao API (Application Programming Interface) responses."
    echo "REASON: This allows us to extract unseal keys, tokens, and secrets from JSON output."
fi

# Check curl
echo ""
echo "4. curl - HTTP (HyperText Transfer Protocol) client for API (Application Programming Interface) requests"
if ! command -v curl &> /dev/null; then
    echo "   ❌ curl is NOT installed"
    echo "   📋 curl is used for HTTP requests to OpenBao API"
    echo "INFO: curl is a command-line tool for making HTTP (HyperText Transfer Protocol) requests to web APIs (Application Programming Interfaces)."
    echo "REASON: We'll use curl to demonstrate direct API access to OpenBao for secret retrieval."
    echo "   💡 Install curl using your system package manager"
    exit 1
else
    echo "   ✅ curl is installed: $(curl --version | head -1)"
    echo "INFO: HTTP (HyperText Transfer Protocol) client is available for making API (Application Programming Interface) requests."
    echo "REASON: This enables direct interaction with OpenBao's REST (Representational State Transfer) API for testing and integration."
fi

echo ""
echo "🎉 All prerequisites are satisfied! Proceeding with setup..."
echo ""
echo "INFO: All required tools are installed and functional."
echo "REASON: We can now proceed with confidence that the setup will complete successfully."

# Ask user if they want to continue
echo ""
read -p "🤔 Do you want to continue with the OpenBao setup? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled by user."
    exit 0
fi

# Container setup
CONTAINER_NAME="openbao-server-demo"

echo ""
read -p "🧹 Ready to clean up existing containers and data? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled by user."
    exit 0
fi

echo "🧹 CLEANUP PHASE"
echo "----------------------------------------"
echo "Removing existing demo container to ensure clean setup..."
echo "INFO: Cleanup ensures we start with a fresh, known state."
echo "REASON: Previous containers might have different configurations or corrupted data."

# Check if our specific container exists and remove it
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "   🛑 Found existing demo container: $CONTAINER_NAME"
    echo "   🛑 Stopping and removing $CONTAINER_NAME..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    echo "   ✅ Container $CONTAINER_NAME removed"
    echo "INFO: Previous demo container has been cleanly removed."
    echo "REASON: This prevents conflicts and ensures we start with fresh configuration."
else
    echo "   ✅ No existing demo container found"
    echo "INFO: No previous demo container exists to clean up."
    echo "REASON: We can proceed directly to creating a new container."
fi

# Check if port 8200 is in use by other containers (but don't remove them)
OTHER_CONTAINERS=$(docker ps --format '{{.Names}} {{.Ports}}' | grep ":8200->" | grep -v "$CONTAINER_NAME" || true)
if [ ! -z "$OTHER_CONTAINERS" ]; then
    echo ""
    echo "   ⚠️  WARNING: Other containers are using port 8200:"
    echo "$OTHER_CONTAINERS" | while read line; do
        echo "      • $line"
    done
    echo "   💡 These containers will NOT be removed (they're not demo containers)"
    echo "   ❓ The setup might fail if port 8200 is busy."
    echo "   📝 You can stop them manually or change the demo port if needed."
    echo "INFO: Port conflict detection protects your existing containers."
    echo "REASON: We respect existing infrastructure while warning about potential conflicts."
    read -p "   Press Enter to continue or Ctrl+C to abort..."
fi

# Clean up old data
echo "   🗑️  Removing old configuration and key files..."
rm -rf ./vault-data
rm -f .vault-keys.json .app-credentials db-policy.hcl vault-config.hcl
echo "   ✅ Old data cleaned up"

echo "   🔒 Ensuring .gitignore exists to protect secrets..."
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'EOF'
# OpenBao Secret Files - NEVER commit these!
.vault-keys.json
.app-credentials
vault-data/
*.pem
*.key
*.crt
vault-config.hcl
*-policy.hcl
*.tmp
*.log
vault.log
vault.pid
EOF
    echo "   ✅ .gitignore created to protect secret files"
else
    echo "   ✅ .gitignore already exists"
fi
echo ""
echo "INFO: Previous configuration files and data have been removed."
echo "REASON: Fresh files ensure no configuration conflicts or stale security credentials."

echo "🚀 STARTING FRESH OPENBAO SETUP"
echo "=========================================="
echo "INFO: Beginning the complete OpenBao deployment process."
echo "REASON: A systematic approach ensures all components are properly configured and integrated."

# Step 1: Container Setup
echo ""
read -p "📦 Ready to create the OpenBao Docker container? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Container setup cancelled by user."
    exit 0
fi

echo ""
echo "📦 STEP 1: CONTAINER SETUP"
echo "----------------------------------------"
echo "Creating OpenBao container with persistent storage..."
echo "INFO: Container setup establishes the runtime environment for OpenBao."
echo "REASON: Containers provide isolation, portability, and consistent deployment across environments."

echo "   📁 Creating local data directory for persistence..."
mkdir -p ./vault-data
chmod 755 ./vault-data
echo "   ✅ Directory './vault-data' created with proper permissions"
echo "INFO: Local directory will store OpenBao's encrypted data persistently."
echo "REASON: Data persistence ensures secrets survive container restarts and updates."

echo ""
echo "   📝 Creating OpenBao configuration file..."
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
echo "   ✅ Configuration saved to 'vault-config.hcl'"
echo "      • File storage backend for persistence"
echo "      • TCP (Transmission Control Protocol) listener on port 8200 (HTTP for demo)"
echo "      • Web UI (User Interface) enabled"
echo "      • Memory locking disabled (for containers)"
echo "INFO: Configuration defines how OpenBao operates and stores data."
echo "REASON: Proper configuration ensures security, accessibility, and container compatibility."

echo ""
echo "   🐳 Starting OpenBao Docker container..."
echo "      Container name: $CONTAINER_NAME"
echo "      Port mapping: 8200:8200 (host:container)"
echo "      Volume mounts: ./vault-data -> /vault/data"
echo "INFO: Container deployment with network and storage configuration."
echo "REASON: Port mapping enables access from host, volume mounts ensure data persistence."

CONTAINER_ID=$(docker run -d \
  --name $CONTAINER_NAME \
  --cap-add=IPC_LOCK \
  -p 8200:8200 \
  -v $(pwd)/vault-data:/vault/data \
  -v $(pwd)/vault-config.hcl:/vault/config/vault-config.hcl \
  openbao/openbao:latest \
  server -config=/vault/config/vault-config.hcl)

echo "   ✅ Container started with ID: ${CONTAINER_ID:0:12}"
echo "   ⏳ Waiting 5 seconds for OpenBao to initialize..."
sleep 5
echo "   🌐 OpenBao UI (User Interface) available at: http://127.0.0.1:8200"
echo "INFO: OpenBao server is now running and accessible via web interface."
echo "REASON: The startup delay ensures the server is fully initialized before configuration."

# Step 2: Initialize
echo ""
read -p "🔐 Ready to initialize OpenBao with master keys? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Vault initialization cancelled by user."
    exit 0
fi

echo ""
echo "🔐 STEP 2: VAULT INITIALIZATION"
echo "----------------------------------------"
echo "Initializing OpenBao with Shamir's Secret Sharing..."
echo "   📊 Key shares: 5 (total pieces of the master key)"
echo "   🔑 Threshold: 3 (minimum pieces needed to unseal)"
echo "   📋 This means any 3 out of 5 keys can unlock the vault"
echo "INFO: Shamir's Secret Sharing splits the master key into multiple pieces."
echo "REASON: This prevents single points of failure - no one person can unlock the vault alone."

export VAULT_ADDR='http://127.0.0.1:8200'

echo ""
echo "   🎲 Generating master key and unseal keys..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > .vault-keys.json

if [ ! -s .vault-keys.json ]; then
    echo "   ❌ Initialization failed!"
    exit 1
fi

echo "   ✅ Vault initialized successfully!"
echo "   💾 Keys and tokens saved to '.vault-keys.json'"
echo "INFO: Master key has been generated and split into 5 shares."
echo "REASON: Key splitting enables distributed control and enhanced security for production use."

# Extract keys
UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' .vault-keys.json)
UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' .vault-keys.json)
UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' .vault-keys.json)
ROOT_TOKEN=$(jq -r '.root_token' .vault-keys.json)

echo "   🔓 Root token generated: ${ROOT_TOKEN:0:8}... (truncated for security)"
echo "INFO: Root token provides administrative access to all OpenBao functions."
echo "REASON: We need administrative privileges to configure authentication and policies."

echo ""
echo "   🔓 UNSEALING VAULT (entering 3 of 5 keys)..."
echo "      Key 1/3: ${UNSEAL_KEY_1:0:8}..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_1 > /dev/null
echo "      Key 2/3: ${UNSEAL_KEY_2:0:8}..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_2 > /dev/null
echo "      Key 3/3: ${UNSEAL_KEY_3:0:8}..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_3 > /dev/null

echo "   ✅ Vault is now UNSEALED and ready for use!"
echo "INFO: OpenBao is now unlocked and can encrypt/decrypt secrets."
echo "REASON: Unsealing activates the cryptographic engine needed for all secret operations."

# Step 3: Configure Authentication
echo ""
read -p "🔑 Ready to configure authentication and security policies? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Authentication setup cancelled by user."
    exit 0
fi

echo ""
echo "🔑 STEP 3: AUTHENTICATION & POLICIES"
echo "----------------------------------------"
echo "Setting up secure access for applications..."
echo "INFO: Authentication and authorization control who can access which secrets."
echo "REASON: Proper access control is essential for production security and compliance."

export VAULT_TOKEN=$ROOT_TOKEN

echo "   🗄️  Enabling KV (Key-Value) v2 secrets engine at path 'secret/'..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao secrets enable -path=secret kv-v2 2>/dev/null || true
echo "   ✅ Key-Value store enabled for storing secrets"
echo "INFO: KV (Key-Value) v2 engine provides versioned secret storage with metadata."
echo "REASON: Versioning allows secret rotation and rollback capabilities for operational safety."

echo ""
echo "   🎭 Enabling AppRole (Application Role) authentication method..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao auth enable approle 2>/dev/null || true
echo "   ✅ AppRole auth enabled (for machine-to-machine authentication)"
echo "INFO: AppRole (Application Role) provides secure authentication for applications and services."
echo "REASON: Applications need non-human authentication that doesn't require interactive login."

echo ""
echo "   📜 Creating security policy for database access..."
cat > db-policy.hcl << 'EOF'
path "secret/data/database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
echo "   ✅ Policy created: allows full access to 'secret/database/*' paths"
echo "INFO: Policies define fine-grained permissions for different secret paths."
echo "REASON: Least-privilege access ensures applications only access secrets they need."

docker cp db-policy.hcl $CONTAINER_NAME:/tmp/db-policy.hcl
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao policy write db-policy /tmp/db-policy.hcl 2>/dev/null || true
echo "   ✅ Policy 'db-policy' uploaded to OpenBao"
echo "INFO: Policy is now active and can be assigned to authentication roles."
echo "REASON: Uploaded policies enable enforcement of access controls for applications."

echo ""
echo "   🤖 Creating AppRole (Application Role) 'flask-app-role' for Flask applications..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write auth/approle/role/flask-app-role \
  token_policies="db-policy" \
  token_ttl=1h \
  token_max_ttl=4h 2>/dev/null || true
echo "   ✅ Flask AppRole created with 1h token TTL (Time To Live) and 4h max TTL (Time To Live)"

echo ""
echo "   🤖 Creating AppRole (Application Role) 'springboot-app-role' for Spring Boot applications..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write auth/approle/role/springboot-app-role \
  token_policies="db-policy" \
  token_ttl=1h \
  token_max_ttl=4h 2>/dev/null || true
echo "   ✅ Spring Boot AppRole created with 1h token TTL (Time To Live) and 4h max TTL (Time To Live)"
echo "INFO: Separate AppRoles (Application Roles) provide isolated authentication for different application types."
echo "REASON: Role separation enables fine-grained access control and audit trails per application framework."

echo ""
echo "   🎫 Generating Flask application credentials..."
FLASK_ROLE_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/flask-app-role/role-id 2>/dev/null || echo "")
FLASK_SECRET_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/flask-app-role/secret-id 2>/dev/null || echo "")

echo ""
echo "   🎫 Generating Spring Boot application credentials..."
SPRINGBOOT_ROLE_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/springboot-app-role/role-id 2>/dev/null || echo "")
SPRINGBOOT_SECRET_ID=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/springboot-app-role/secret-id 2>/dev/null || echo "")

if [ ! -z "$FLASK_ROLE_ID" ] && [ ! -z "$FLASK_SECRET_ID" ] && [ ! -z "$SPRINGBOOT_ROLE_ID" ] && [ ! -z "$SPRINGBOOT_SECRET_ID" ]; then
    cat > .app-credentials << EOF
# Flask Application Credentials
FLASK_ROLE_ID=$FLASK_ROLE_ID
FLASK_SECRET_ID=$FLASK_SECRET_ID

# Spring Boot Application Credentials
SPRINGBOOT_ROLE_ID=$SPRINGBOOT_ROLE_ID
SPRINGBOOT_SECRET_ID=$SPRINGBOOT_SECRET_ID
EOF
    echo "   ✅ Application credentials saved to '.app-credentials'"
    echo "      Flask Role ID (Identifier): ${FLASK_ROLE_ID:0:8}... (public identifier)"
    echo "      Flask Secret ID (Identifier): ${FLASK_SECRET_ID:0:8}... (private credential)"
    echo "      Spring Boot Role ID (Identifier): ${SPRINGBOOT_ROLE_ID:0:8}... (public identifier)"
    echo "      Spring Boot Secret ID (Identifier): ${SPRINGBOOT_SECRET_ID:0:8}... (private credential)"
    echo "INFO: Separate Role IDs (Identifiers) and Secret IDs (Identifiers) authenticate each application type to OpenBao."
    echo "REASON: Application-specific credentials enable tracking and controlling access per framework type."
else
    echo "   ⚠️  Warning: Could not generate application credentials"
    echo "INFO: Credential generation failed - manual configuration may be needed."
    echo "REASON: Applications won't be able to authenticate without valid Role ID and Secret ID pairs."
fi

# Step 4: Store Demo Secrets
echo ""
read -p "💾 Ready to store demo database credentials? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Demo secrets storage cancelled by user."
    exit 0
fi

echo ""
echo "💾 STEP 4: STORING DEMO SECRETS"
echo "----------------------------------------"
echo "Adding sample database credentials for testing..."
echo "INFO: Demo secrets provide realistic data for testing application integration."
echo "REASON: Sample data helps verify the complete workflow from storage to retrieval."

echo "   📝 Storing demo database credentials at 'secret/database/demo'..."
echo "      Username: demo_db_user"
echo "      Password: demo_db_pwd"
echo "INFO: Secrets are stored in the KV (Key-Value) engine under organized paths."
echo "REASON: Structured paths enable logical organization and policy-based access control."

docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao kv put secret/database/demo \
  username="demo_db_user" \
  password="demo_db_pwd" 2>/dev/null || true

echo "   ✅ Demo secrets stored successfully!"
echo "INFO: Secrets are now encrypted and stored in OpenBao's secure storage."
echo "REASON: Encrypted storage protects sensitive data even if the underlying storage is compromised."

# Step 5: Refresh Credentials
echo ""
read -p "🔄 Ready to refresh application credentials? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Credentials refresh cancelled by user."
    exit 0
fi

echo ""
echo "🔄 STEP 5: REFRESHING APPLICATION CREDENTIALS"
echo "----------------------------------------"
echo "Generating fresh credentials for applications..."
echo "INFO: Fresh credentials ensure applications have current access tokens."
echo "REASON: Regular credential refresh is a security best practice for production systems."

echo ""
echo "   🎫 Generating fresh Flask application credentials..."
FLASK_ROLE_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/flask-app-role/role-id 2>/dev/null || echo "")
FLASK_SECRET_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/flask-app-role/secret-id 2>/dev/null || echo "")

echo ""
echo "   🎫 Generating fresh Spring Boot application credentials..."
SPRINGBOOT_ROLE_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao read -field=role_id auth/approle/role/springboot-app-role/role-id 2>/dev/null || echo "")
SPRINGBOOT_SECRET_ID=$(docker exec -e VAULT_TOKEN=$ROOT_TOKEN $CONTAINER_NAME bao write -field=secret_id -f auth/approle/role/springboot-app-role/secret-id 2>/dev/null || echo "")

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
    echo "   ✅ Fresh application credentials saved to '.app-credentials'"
    echo "      Flask Role ID (Identifier): ${FLASK_ROLE_ID:0:8}... (public identifier)"
    echo "      Flask Secret ID (Identifier): ${FLASK_SECRET_ID:0:8}... (private credential)"
    echo "      Spring Boot Role ID (Identifier): ${SPRINGBOOT_ROLE_ID:0:8}... (public identifier)"
    echo "      Spring Boot Secret ID (Identifier): ${SPRINGBOOT_SECRET_ID:0:8}... (private credential)"
    echo "INFO: Fresh Role IDs (Identifiers) and Secret IDs (Identifiers) provide current authentication to OpenBao."
    echo "REASON: New credentials ensure applications have valid, unexpired access tokens."
else
    echo "   ⚠️  Warning: Could not generate fresh application credentials"
    echo "INFO: Credential generation failed - manual configuration may be needed."
    echo "REASON: Applications won't be able to authenticate without valid Role ID and Secret ID pairs."
fi

# Final Summary
echo ""
echo "🎉 SETUP COMPLETE!"
echo "=========================================="
echo "Your OpenBao environment is ready for use:"
echo ""
echo "INFO: Complete secrets management infrastructure is now operational."
echo "REASON: All components work together to provide secure, scalable secret storage and access."

echo "📊 CONTAINER INFORMATION:"
echo "   Name: $CONTAINER_NAME"
echo "   Status: $(docker ps --format 'table {{.Status}}' --filter name=$CONTAINER_NAME | tail -1)"
echo "   Port: 8200 (HTTP)"
echo ""
echo "INFO: Container details help with monitoring and troubleshooting."
echo "REASON: Knowing container status and configuration aids in operational management."

echo "🌐 ACCESS POINTS:"
echo "   Web UI (User Interface): http://127.0.0.1:8200"
echo "   API (Application Programming Interface): http://127.0.0.1:8200/v1/"
echo "   Root Token: $ROOT_TOKEN"
echo ""
echo "INFO: Multiple access methods support different use cases and integrations."
echo "REASON: Web UI (User Interface) for human interaction, API (Application Programming Interface) for programmatic access, tokens for authentication."

echo "🗂️  DEMO DATA:"
echo "   Path: secret/database/demo"
echo "   Username: demo_db_user"
echo "   Password: demo_db_pwd"
echo ""
echo "INFO: Sample data demonstrates real-world secret storage patterns."
echo "REASON: Realistic examples help understand how to organize and access secrets in applications."

echo "📁 FILES CREATED:"
echo "   .vault-keys.json - Unseal keys and root token (KEEP SECURE!)"
echo "   .app-credentials - AppRole credentials for Flask and Spring Boot applications"
echo "   vault-data/ - Persistent OpenBao data directory"
echo "   vault-config.hcl - OpenBao server configuration"
echo "   db-policy.hcl - Security policy definition"
echo ""
echo "INFO: Generated files contain critical security credentials and configuration."
echo "REASON: Understanding file purposes helps with backup, security, and operational procedures."

echo "🛠️  MANAGEMENT COMMANDS:"
echo "   docker stop $CONTAINER_NAME     # Stop the container"
echo "   docker start $CONTAINER_NAME    # Start the container"
echo "   docker logs $CONTAINER_NAME     # View container logs"
echo "   ./manage-docker-vault.sh start  # Start with auto-unseal"
echo ""
echo "INFO: Management commands provide operational control over the OpenBao instance."
echo "REASON: Regular operations like start/stop/monitoring are essential for production use."

echo "🧪 TESTING:"
echo "   ./app-access-demo.sh            # Test secret retrieval"
echo "   curl http://localhost:5000/db-credentials  # Test Flask app"
echo "   curl http://localhost:8080/db-credentials  # Test Spring Boot app"
echo ""
echo "INFO: Testing commands verify that the complete integration works correctly."
echo "REASON: Validation ensures applications can successfully authenticate and retrieve secrets."

echo "📚 NEXT STEPS:"
echo "   1. Visit the Web UI to explore OpenBao features"
echo "   2. Run the demo applications to see integration"
echo "   3. Try retrieving secrets using the API"
echo "   4. Experiment with different authentication methods"
echo ""
echo "INFO: Suggested next steps help you learn OpenBao capabilities hands-on."
echo "REASON: Progressive exploration builds understanding of features and use cases."

echo "⚠️  SECURITY REMINDER:"
echo "   This is a DEMO setup with HTTP (HyperText Transfer Protocol) and relaxed security."
echo "   For production, enable TLS (Transport Layer Security), use proper authentication,"
echo "   and secure your unseal keys properly!"
echo "   🔒 IMPORTANT: Secret files are protected by .gitignore - NEVER commit them to version control!"
echo ""
echo "INFO: Security reminder highlights the difference between demo and production setups."
echo "REASON: Understanding security implications prevents unsafe practices in real deployments."
