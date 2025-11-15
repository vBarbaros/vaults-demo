# OpenBao Docker Setup Scripts

This directory contains Docker-based OpenBao setup scripts for secrets management.

## Prerequisites

- Docker Desktop running
- `jq` utility installed (`brew install jq`)
- `curl` utility (pre-installed on macOS)

## Complete Setup (Recommended)

```bash
./complete-docker-setup.sh
```

This runs all setup steps automatically and provides a fully configured OpenBao instance.

## Individual Setup Steps

### Step 1: Container Setup
```bash
./setup-docker-openbao.sh
```
**What it does:**
- Creates local `vault-data` directory for persistent storage
- Creates OpenBao configuration file (`vault-config.hcl`)
- Pulls and starts OpenBao Docker container on port 8200
- Maps local directories to container for data persistence

### Step 2: Initialize OpenBao
```bash
./init-docker-openbao.sh
```
**What it does:**
- Initializes OpenBao with 5 key shares (3 required to unseal)
- Saves unseal keys and root token to `.vault-keys.json`
- Automatically unseals the vault using 3 keys
- Makes OpenBao ready for configuration

### Step 3: Configure Authentication
```bash
./configure-docker-auth.sh
```
**What it does:**
- Enables KV v2 secrets engine at path `secret/`
- Enables AppRole authentication method
- Creates `db-policy` allowing access to `secret/database/*`
- Creates `db-app` role with the policy
- Generates Role ID and Secret ID for applications
- Saves credentials to `.app-credentials` file

### Step 4: Store Demo Secrets
```bash
./store-demo-secrets.sh
```
**What it does:**
- Stores demo database credentials at `secret/database/demo`
- Username: `demo_db_user`
- Password: `demo_db_pwd`
- Verifies the secrets were stored correctly

## Container Management

### Start/Stop Container
```bash
./manage-docker-vault.sh start    # Start and auto-unseal
./manage-docker-vault.sh stop     # Stop container
./manage-docker-vault.sh status   # Show container status
./manage-docker-vault.sh logs     # View container logs
```

### Test Secret Retrieval
```bash
./app-access-demo.sh
```
**What it does:**
- Authenticates using Flask AppRole (Role ID + Secret ID)
- Retrieves database credentials from OpenBao
- Displays the retrieved username and password

### Refresh Application Credentials
```bash
./refresh-credentials.sh
```
**What it does:**
- Generates fresh Secret IDs for both Flask and Spring Boot AppRoles
- Updates the .app-credentials file with new credentials
- Maintains the same Role IDs but refreshes Secret IDs for security

## Access Points

- **OpenBao UI:** http://127.0.0.1:8200
- **API Endpoint:** http://127.0.0.1:8200/v1/
- **Demo Secrets Path:** `secret/database/demo`

## Integration Testing

After setup, test with the demo applications:

```bash
# Flask app (from project root)
cd ../flask-app && ./run.sh
curl http://localhost:5000/db-credentials

# Spring Boot app (from project root)  
cd ../spring-boot-app && ./run.sh
curl http://localhost:8080/db-credentials
```

## Files Created

- `.vault-keys.json` - Unseal keys and root token (keep secure!)
- `.app-credentials` - AppRole credentials for applications
- `vault-data/` - Persistent OpenBao data directory
- `vault-config.hcl` - OpenBao configuration
- `db-policy.hcl` - Database access policy

## Security Notes

- Store `.vault-keys.json` securely and separately in production
- Use `chmod 600` on credential files
- Enable TLS for production deployments
- Implement secret rotation policies
