#!/bin/bash

# Load credentials if they exist
if [ -f "../.app-credentials" ]; then
    source ../.app-credentials
    # Use Spring Boot-specific credentials if available, fallback to legacy
    export ROLE_ID=${SPRINGBOOT_ROLE_ID:-$ROLE_ID}
    export SECRET_ID=${SPRINGBOOT_SECRET_ID:-$SECRET_ID}
elif [ -f "../openbao-vault/.app-credentials" ]; then
    source ../openbao-vault/.app-credentials
    # Use Spring Boot-specific credentials if available, fallback to legacy
    export ROLE_ID=${SPRINGBOOT_ROLE_ID:-$ROLE_ID}
    export SECRET_ID=${SPRINGBOOT_SECRET_ID:-$SECRET_ID}
fi

export VAULT_ADDR='http://127.0.0.1:8200'

echo "Starting Spring Boot application with OpenBao integration..."
echo "Using Role ID: ${ROLE_ID:0:8}..."

# Build and run Spring Boot app
./mvnw clean spring-boot:run
