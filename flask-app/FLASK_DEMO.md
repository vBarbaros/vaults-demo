# Flask OpenBao Integration Demo

This demo shows how to integrate a Flask application with OpenBao for secure database credential management.

## Prerequisites

1. **OpenBao Setup Complete:**
   ```bash
   cd ../openbao-vault
   ./complete-docker-setup.sh
   ```

2. **Python 3.8+ installed**

3. **Flask AppRole credentials available in `.app-credentials`**

## Project Structure

```
flask-app/
├── FLASK_DEMO.md          # This documentation
├── requirements.txt       # Python dependencies
├── vault_client.py        # OpenBao client wrapper
├── app.py                # Main Flask application
└── run.sh                # Startup script
```

## How It Works

### 1. OpenBao Authentication
The Flask app uses **AppRole authentication** to connect to OpenBao:
- **Role ID**: Public identifier for the Flask application
- **Secret ID**: Private credential (rotated regularly)
- **Token**: Temporary access token obtained after authentication

### 2. Secret Retrieval
Once authenticated, the app retrieves database credentials from:
- **Path**: `secret/database/demo`
- **Username**: `demo_db_user`
- **Password**: `demo_db_pwd`

### 3. Application Flow
```
Flask App → AppRole Auth → OpenBao → Database Credentials → Response
```

## Running the Demo

### Step 1: Start the Flask Application
```bash
./run.sh
```

**What happens:**
- Loads Flask AppRole credentials from `../openbao-vault/.app-credentials`
- Installs Python dependencies
- Starts Flask server on http://localhost:5000

### Step 2: Test the Endpoints

**Home Page:**
```bash
curl http://localhost:5000/
```
**Response:**
```json
{
  "message": "Flask OpenBao Demo",
  "status": "running"
}
```

**Database Credentials:**
```bash
curl http://localhost:5000/db-credentials
```
**Response:**
```json
{
  "username": "demo_db_user",
  "password": "demo_db_pwd"
}
```

**Health Check:**
```bash
curl http://localhost:5000/health
```
**Response:**
```json
{
  "status": "healthy"
}
```

## Code Walkthrough

### vault_client.py
```python
import hvac
import os

class VaultClient:
    def __init__(self):
        self.vault_url = os.getenv('VAULT_ADDR', 'http://127.0.0.1:8200')
        self.role_id = os.getenv('ROLE_ID')      # Flask Role ID
        self.secret_id = os.getenv('SECRET_ID')  # Flask Secret ID
        self.client = hvac.Client(url=self.vault_url)
        self._authenticate()
    
    def _authenticate(self):
        # AppRole authentication
        if self.role_id and self.secret_id:
            response = self.client.auth.approle.login(
                role_id=self.role_id,
                secret_id=self.secret_id
            )
            self.client.token = response['auth']['client_token']
    
    def get_secret(self, path):
        # Retrieve secrets from OpenBao
        try:
            response = self.client.secrets.kv.v2.read_secret_version(path=path)
            return response['data']['data']
        except Exception as e:
            return {'error': str(e)}
```

### app.py
```python
from flask import Flask, jsonify
from vault_client import VaultClient

app = Flask(__name__)
vault_client = VaultClient()

@app.route('/db-credentials')
def get_db_credentials():
    # Get database credentials from OpenBao
    secrets = vault_client.get_secret('database/demo')
    return jsonify(secrets)
```

## Configuration Details

### Environment Variables
The `run.sh` script sets these automatically:
- `VAULT_ADDR=http://127.0.0.1:8200` - OpenBao server URL
- `ROLE_ID=<flask_role_id>` - Flask AppRole identifier
- `SECRET_ID=<flask_secret_id>` - Flask AppRole secret

### Dependencies (requirements.txt)
```txt
Flask==3.0.0
hvac==2.1.0
requests==2.31.0
```

## Troubleshooting

### Common Issues

**1. "No credentials found" error:**
```bash
# Solution: Run OpenBao setup first
cd ../openbao-vault
./complete-docker-setup.sh
```

**2. "Authentication failed" error:**
```bash
# Solution: Refresh credentials
cd ../openbao-vault
./refresh-credentials.sh
```

**3. "Connection refused" error:**
```bash
# Solution: Check if OpenBao container is running
docker ps | grep openbao-server-demo
# If not running:
cd ../openbao-vault
./manage-docker-vault.sh start
```

**4. "Secret not found" error:**
```bash
# Solution: Verify demo secrets exist
cd ../openbao-vault
./app-access-demo.sh
```

### Debug Mode
Run Flask in debug mode for detailed error messages:
```bash
export FLASK_DEBUG=1
python3 app.py
```

## Security Best Practices

### In This Demo
- ✅ AppRole authentication (no hardcoded credentials)
- ✅ Temporary tokens with TTL
- ✅ Secrets retrieved dynamically
- ✅ Error handling for failed authentication

### For Production
- 🔒 Enable TLS/HTTPS
- 🔒 Use proper certificate validation
- 🔒 Implement secret rotation
- 🔒 Add audit logging
- 🔒 Use network policies
- 🔒 Implement token renewal

## Integration with Real Databases

To use with actual databases, modify the secret retrieval:

```python
def get_db_connection():
    # Get credentials from OpenBao
    creds = vault_client.get_secret('database/production')
    
    # Connect to database
    import psycopg2  # or your database driver
    conn = psycopg2.connect(
        host=creds['host'],
        database=creds['database'],
        user=creds['username'],
        password=creds['password']
    )
    return conn
```

## Next Steps

1. **Explore the Spring Boot demo:** `../spring-boot-app/`
2. **Try credential rotation:** `../openbao-vault/refresh-credentials.sh`
3. **Experiment with different secret paths**
4. **Add your own database integration**
5. **Implement secret caching for performance**

This demo provides a foundation for secure secret management in Flask applications using OpenBao!
