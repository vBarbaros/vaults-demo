#!/bin/bash

# Load credentials if they exist
if [ -f "../.app-credentials" ]; then
    source ../.app-credentials
    export ROLE_ID=$SPRINGBOOT_ROLE_ID
    export SECRET_ID=$SPRINGBOOT_SECRET_ID
elif [ -f "../openbao-vault/.app-credentials" ]; then
    source ../openbao-vault/.app-credentials
    export ROLE_ID=$SPRINGBOOT_ROLE_ID
    export SECRET_ID=$SPRINGBOOT_SECRET_ID
else
    echo "❌ No credentials found. Run the OpenBao setup first."
    exit 1
fi

export VAULT_ADDR='http://127.0.0.1:8200'

echo "Starting Spring Boot application with OpenBao integration..."
echo "Using Spring Boot Role ID: ${ROLE_ID:0:8}..."

# Build and run Spring Boot app
./mvnw clean spring-boot:run
