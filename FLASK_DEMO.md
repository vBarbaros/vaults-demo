# Flask OpenBao Integration Demo

This demo shows the minimal setup required to integrate a Flask application with OpenBao for secret management.

## Project Structure

```
flask-vault-demo/
├── requirements.txt
├── app.py
├── vault_client.py
├── config.py
└── run.sh
```

## Dependencies (requirements.txt)

```txt
Flask==3.0.0
hvac==2.1.0
python-dotenv==1.0.0
requests==2.31.0
```

## Configuration (config.py)

```python
# config.py
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    VAULT_URL = os.getenv('VAULT_ADDR', 'http://127.0.0.1:8200')
    ROLE_ID = os.getenv('ROLE_ID')
    SECRET_ID = os.getenv('SECRET_ID')
    VAULT_MOUNT_POINT = 'secret'
    SECRET_PATH = 'database/demo'
    
    @classmethod
    def validate(cls):
        if not cls.ROLE_ID or not cls.SECRET_ID:
            raise ValueError("ROLE_ID and SECRET_ID environment variables are required")
```

## Vault Client (vault_client.py)

```python
# vault_client.py
import hvac
import logging
from config import Config

logger = logging.getLogger(__name__)

class VaultClient:
    def __init__(self):
        self.client = hvac.Client(url=Config.VAULT_URL)
        self._authenticate()
    
    def _authenticate(self):
        """Authenticate using AppRole method"""
        try:
            auth_response = self.client.auth.approle.login(
                role_id=Config.ROLE_ID,
                secret_id=Config.SECRET_ID
            )
            self.client.token = auth_response['auth']['client_token']
            logger.info("Successfully authenticated with OpenBao")
        except Exception as e:
            logger.error(f"Failed to authenticate with OpenBao: {e}")
            raise
    
    def get_secret(self, path):
        """Retrieve secret from OpenBao"""
        try:
            full_path = f"{Config.VAULT_MOUNT_POINT}/data/{path}"
            response = self.client.secrets.kv.v2.read_secret_version(
                path=path,
                mount_point=Config.VAULT_MOUNT_POINT
            )
            return response['data']['data']
        except Exception as e:
            logger.error(f"Failed to retrieve secret from {path}: {e}")
            raise
    
    def get_database_credentials(self):
        """Get database credentials from OpenBao"""
        return self.get_secret(Config.SECRET_PATH)
    
    def is_healthy(self):
        """Check if vault connection is healthy"""
        try:
            return self.client.sys.is_initialized() and not self.client.sys.is_sealed()
        except Exception:
            return False
```

## Flask Application (app.py)

```python
# app.py
from flask import Flask, jsonify
import logging
from vault_client import VaultClient
from config import Config

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Initialize Vault client
try:
    Config.validate()
    vault_client = VaultClient()
    logger.info("Flask app initialized with OpenBao integration")
except Exception as e:
    logger.error(f"Failed to initialize OpenBao client: {e}")
    vault_client = None

@app.route('/health')
def health():
    """Health check endpoint"""
    vault_status = "connected" if vault_client and vault_client.is_healthy() else "disconnected"
    return jsonify({
        "status": "UP",
        "vault": vault_status
    })

@app.route('/db-info')
def get_database_info():
    """Get database credentials info (password masked)"""
    if not vault_client:
        return jsonify({"error": "Vault client not initialized"}), 500
    
    try:
        credentials = vault_client.get_database_credentials()
        return jsonify({
            "username": credentials.get("username"),
            "password": "***HIDDEN***",
            "status": "credentials_retrieved"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/connection-string')
def get_connection_string():
    """Get database connection string (password masked)"""
    if not vault_client:
        return jsonify({"error": "Vault client not initialized"}), 500
    
    try:
        credentials = vault_client.get_database_credentials()
        username = credentials.get("username")
        password = credentials.get("password")
        
        # Create connection string
        connection_string = f"postgresql://{username}:{password}@localhost:5432/demo"
        
        # Mask password for response
        masked_connection = connection_string.replace(f":{password}@", ":***@")
        
        return jsonify({
            "connection": masked_connection,
            "status": "connection_string_generated"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/secrets/raw')
def get_raw_secrets():
    """Get raw secrets (for demo purposes only - not for production)"""
    if not vault_client:
        return jsonify({"error": "Vault client not initialized"}), 500
    
    try:
        credentials = vault_client.get_database_credentials()
        return jsonify({
            "warning": "This endpoint exposes raw secrets - for demo only",
            "credentials": credentials
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

## Environment File (.env)

```bash
# .env
VAULT_ADDR=http://127.0.0.1:8200
ROLE_ID=your_role_id_here
SECRET_ID=your_secret_id_here
```

## Setup and Run Scripts

### Setup Script

```bash
#!/bin/bash
# setup-flask-demo.sh

echo "Setting up Flask OpenBao Demo..."

# Create project directory
mkdir -p flask-vault-demo
cd flask-vault-demo

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install Flask==3.0.0 hvac==2.1.0 python-dotenv==1.0.0 requests==2.31.0

# Create requirements.txt
pip freeze > requirements.txt

echo "Flask demo project created!"
echo "Next steps:"
echo "1. Ensure OpenBao is running with demo secrets"
echo "2. Update .env file with your ROLE_ID and SECRET_ID"
echo "3. Run: ./run-flask-demo.sh"
```

### Run Script

```bash
#!/bin/bash
# run-flask-demo.sh

# Load OpenBao credentials
if [ -f ../.app-credentials ]; then
    source ../.app-credentials
    echo "Loaded OpenBao credentials"
else
    echo "Error: .app-credentials file not found"
    echo "Run the OpenBao setup scripts first"
    exit 1
fi

# Create .env file with credentials
cat > flask-vault-demo/.env << EOF
VAULT_ADDR=http://127.0.0.1:8200
ROLE_ID=$ROLE_ID
SECRET_ID=$SECRET_ID
EOF

echo "Starting Flask application..."
echo "ROLE_ID: ${ROLE_ID:0:8}..."
echo "SECRET_ID: ${SECRET_ID:0:8}..."

# Activate virtual environment and run
cd flask-vault-demo
source venv/bin/activate
python app.py
```

### Test Script

```bash
#!/bin/bash
# test-flask-demo.sh

echo "Testing Flask OpenBao integration..."

BASE_URL="http://localhost:5000"

echo "1. Health check:"
curl -s $BASE_URL/health | python3 -m json.tool

echo -e "\n2. Database info:"
curl -s $BASE_URL/db-info | python3 -m json.tool

echo -e "\n3. Connection string:"
curl -s $BASE_URL/connection-string | python3 -m json.tool

echo -e "\n4. Raw secrets (demo only):"
curl -s $BASE_URL/secrets/raw | python3 -m json.tool

echo -e "\nDemo complete!"
```

## Advanced Integration Example

### Database Service Class

```python
# database_service.py
import psycopg2
from vault_client import VaultClient
import logging

logger = logging.getLogger(__name__)

class DatabaseService:
    def __init__(self):
        self.vault_client = VaultClient()
    
    def get_connection(self):
        """Get database connection using OpenBao credentials"""
        try:
            credentials = self.vault_client.get_database_credentials()
            
            connection = psycopg2.connect(
                host="localhost",
                port=5432,
                database="demo",
                user=credentials["username"],
                password=credentials["password"]
            )
            
            logger.info("Database connection established")
            return connection
            
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            raise
    
    def test_connection(self):
        """Test database connectivity"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            cursor.close()
            conn.close()
            return result[0] == 1
        except Exception as e:
            logger.error(f"Database connection test failed: {e}")
            return False
```

### Enhanced Flask App with Database

```python
# enhanced_app.py
from flask import Flask, jsonify
from database_service import DatabaseService
from vault_client import VaultClient
from config import Config
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Initialize services
try:
    Config.validate()
    vault_client = VaultClient()
    db_service = DatabaseService()
    logger.info("Enhanced Flask app initialized")
except Exception as e:
    logger.error(f"Failed to initialize services: {e}")
    vault_client = None
    db_service = None

@app.route('/health')
def health():
    """Comprehensive health check"""
    vault_healthy = vault_client and vault_client.is_healthy()
    db_healthy = db_service and db_service.test_connection() if vault_healthy else False
    
    return jsonify({
        "status": "UP" if vault_healthy else "DOWN",
        "vault": "connected" if vault_healthy else "disconnected",
        "database": "connected" if db_healthy else "disconnected"
    })

@app.route('/db-test')
def test_database():
    """Test database connection"""
    if not db_service:
        return jsonify({"error": "Database service not initialized"}), 500
    
    try:
        is_connected = db_service.test_connection()
        return jsonify({
            "database_test": "passed" if is_connected else "failed",
            "message": "Database connection successful" if is_connected else "Database connection failed"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

## Docker Integration

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  vault:
    image: openbao/openbao:latest
    container_name: vault-server
    ports:
      - "8200:8200"
    volumes:
      - ./vault-data:/vault/data
      - ./vault-config.hcl:/vault/config/vault-config.hcl
    command: server -config=/vault/config/vault-config.hcl
    cap_add:
      - IPC_LOCK

  flask-app:
    build: .
    container_name: flask-vault-demo
    ports:
      - "5000:5000"
    environment:
      - VAULT_ADDR=http://vault:8200
      - ROLE_ID=${ROLE_ID}
      - SECRET_ID=${SECRET_ID}
    depends_on:
      - vault
```

## Complete Demo Workflow

### 1. Setup OpenBao (if not done)

```bash
# From the openbao-config directory
./complete-docker-setup.sh
```

### 2. Create Flask Project

```bash
# Create the Flask demo project
./setup-flask-demo.sh
```

### 3. Run Application

```bash
# Run with OpenBao credentials
./run-flask-demo.sh
```

### 4. Test Integration

```bash
# Test the endpoints
./test-flask-demo.sh
```

## Expected Output

```json
// GET /health
{
  "status": "UP",
  "vault": "connected"
}

// GET /db-info
{
  "username": "demo_db_user",
  "password": "***HIDDEN***",
  "status": "credentials_retrieved"
}

// GET /connection-string
{
  "connection": "postgresql://demo_db_user:***@localhost:5432/demo",
  "status": "connection_string_generated"
}

// GET /secrets/raw
{
  "warning": "This endpoint exposes raw secrets - for demo only",
  "credentials": {
    "username": "demo_db_user",
    "password": "demo_db_pwd"
  }
}
```

## Production Enhancements

### Secret Caching

```python
# cached_vault_client.py
import time
from vault_client import VaultClient

class CachedVaultClient(VaultClient):
    def __init__(self, cache_ttl=300):  # 5 minutes
        super().__init__()
        self.cache = {}
        self.cache_ttl = cache_ttl
    
    def get_secret(self, path):
        now = time.time()
        cache_key = path
        
        if cache_key in self.cache:
            cached_data, timestamp = self.cache[cache_key]
            if now - timestamp < self.cache_ttl:
                return cached_data
        
        # Fetch fresh data
        data = super().get_secret(path)
        self.cache[cache_key] = (data, now)
        return data
```

## Key Integration Points

1. **AppRole Authentication**: Secure authentication using role-id/secret-id
2. **HVAC Library**: Official HashiCorp Vault client for Python
3. **Error Handling**: Comprehensive error handling for vault operations
4. **Health Checks**: Vault connectivity monitoring
5. **Security**: Password masking in API responses
6. **Environment Configuration**: Flexible configuration via environment variables

## Production Considerations

- Use HTTPS for vault communication
- Implement proper logging and monitoring
- Add secret rotation handling
- Use connection pooling for database connections
- Implement circuit breaker pattern for vault calls
- Add comprehensive error handling and retries
- Use proper secret caching with TTL

This minimal Flask demo provides a complete foundation for integrating Python applications with OpenBao for secure secret management.
