#!/bin/bash

# Load credentials if they exist
if [ -f "../openbao-vault/.app-credentials" ]; then
    source ../openbao-vault/.app-credentials
    export ROLE_ID=$FLASK_ROLE_ID
    export SECRET_ID=$FLASK_SECRET_ID
    echo "✅ Loaded Flask credentials from ../openbao-vault/.app-credentials"
elif [ -f "../.app-credentials" ]; then
    source ../.app-credentials
    export ROLE_ID=$FLASK_ROLE_ID
    export SECRET_ID=$FLASK_SECRET_ID
    echo "✅ Loaded Flask credentials from ../.app-credentials"
else
    echo "❌ No credentials found. Run the OpenBao setup first:"
    echo "   cd ../openbao-vault && ./complete-docker-setup.sh"
    exit 1
fi

export VAULT_ADDR='http://127.0.0.1:8200'

echo "Starting Flask application with OpenBao integration..."
echo "Using Flask Role ID: ${ROLE_ID:0:8}..."
echo "Vault Address: $VAULT_ADDR"

# Check if credentials are properly set
if [ -z "$ROLE_ID" ] || [ -z "$SECRET_ID" ]; then
    echo "❌ Error: Flask credentials not found in .app-credentials file"
    echo "   Run: cd ../openbao-vault && ./refresh-credentials.sh"
    exit 1
fi

# Install dependencies (handle macOS Homebrew Python issues)
echo "Installing Python dependencies..."
python3 -m pip install --break-system-packages -r requirements.txt > /dev/null 2>&1

# Verify Flask is available
if ! python3 -c "import flask" 2>/dev/null; then
    echo "❌ Error: Flask installation failed"
    echo "   Try: python3 -m pip install --break-system-packages flask hvac requests"
    exit 1
fi

# Run Flask app
echo "Starting Flask server on http://localhost:5000"
echo "Press Ctrl+C to stop the server"
echo ""
echo "Test endpoints:"
echo "  curl http://localhost:5000/"
echo "  curl http://localhost:5000/db-credentials"
echo ""

python3 app.py
