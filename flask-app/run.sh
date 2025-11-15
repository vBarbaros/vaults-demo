#!/bin/bash

# Load credentials if they exist
if [ -f "../.app-credentials" ]; then
    source ../.app-credentials
    # Use Flask-specific credentials if available, fallback to legacy
    export ROLE_ID=${FLASK_ROLE_ID:-$ROLE_ID}
    export SECRET_ID=${FLASK_SECRET_ID:-$SECRET_ID}
elif [ -f "../openbao-vault/.app-credentials" ]; then
    source ../openbao-vault/.app-credentials
    # Use Flask-specific credentials if available, fallback to legacy
    export ROLE_ID=${FLASK_ROLE_ID:-$ROLE_ID}
    export SECRET_ID=${FLASK_SECRET_ID:-$SECRET_ID}
fi

export VAULT_ADDR='http://127.0.0.1:8200'

echo "Starting Flask application with OpenBao integration..."
echo "Using Role ID: ${ROLE_ID:0:8}..."

# Install dependencies
pip3 install -r requirements.txt

# Run Flask app
python3 app.py
