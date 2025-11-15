#!/bin/bash

# Load credentials if they exist
if [ -f "../openbao-vault/.app-credentials" ]; then
    source ../openbao-vault/.app-credentials
    export ROLE_ID=$SPRINGBOOT_ROLE_ID
    export SECRET_ID=$SPRINGBOOT_SECRET_ID
    echo "✅ Loaded Spring Boot credentials from ../openbao-vault/.app-credentials"
elif [ -f "../.app-credentials" ]; then
    source ../.app-credentials
    export ROLE_ID=$SPRINGBOOT_ROLE_ID
    export SECRET_ID=$SPRINGBOOT_SECRET_ID
    echo "✅ Loaded Spring Boot credentials from ../.app-credentials"
else
    echo "❌ No credentials found. Run the OpenBao setup first:"
    echo "   cd ../openbao-vault && ./complete-docker-setup.sh"
    exit 1
fi

export VAULT_ADDR='http://127.0.0.1:8200'

echo "Starting Spring Boot application with OpenBao integration..."
echo "Using Spring Boot Role ID: ${ROLE_ID:0:8}..."
echo "Vault Address: $VAULT_ADDR"

# Check if credentials are properly set
if [ -z "$ROLE_ID" ] || [ -z "$SECRET_ID" ]; then
    echo "❌ Error: Spring Boot credentials not found in .app-credentials file"
    echo "   Run: cd ../openbao-vault && ./refresh-credentials.sh"
    exit 1
fi

# Check if Gradle is available
if command -v gradle &> /dev/null; then
    GRADLE_CMD="gradle"
elif [ -x "./gradlew" ]; then
    GRADLE_CMD="./gradlew"
else
    echo "❌ Error: Gradle not found. Install Gradle:"
    echo "   brew install gradle"
    exit 1
fi

echo "Building and starting Spring Boot application with Gradle..."
echo "This may take a moment on first run..."
echo ""
echo "Spring Boot will start on http://localhost:8080"
echo "Press Ctrl+C to stop the server"
echo ""
echo "Test endpoints:"
echo "  curl http://localhost:8080/"
echo "  curl http://localhost:8080/db-credentials"
echo ""

# Build and run Spring Boot app with Gradle
$GRADLE_CMD clean bootRun
