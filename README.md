# OpenBao Vaults Demo

A comprehensive demonstration project showing how to set up and integrate OpenBao (open-source HashiCorp Vault fork) for secrets management across different deployment scenarios and application frameworks.

## Author

**vBarbaros** (victor.barbarosh@gmail.com)

## Contents

This repository contains:

- **DEMO_README.md** - Complete OpenBao setup guide with two deployment options:
  - Docker container deployment (isolated, portable)
  - System service deployment (native performance)
- **SPRING_BOOT_DEMO.md** - Spring Boot application integration with OpenBao
- **FLASK_DEMO.md** - Flask application integration with OpenBao
- **flask-app/** - Working Flask application with OpenBao integration
- **spring-boot-app/** - Working Spring Boot application with OpenBao integration

## What This Demo Covers

- OpenBao installation and configuration
- Vault initialization and unsealing
- AppRole authentication setup
- Secret storage and retrieval
- Application integration patterns
- Security best practices
- Troubleshooting guides

## Quick Start

1. **Choose your deployment method:**
   - For containerized setup: Follow Docker instructions in `DEMO_README.md`
   - For system service: Follow Service instructions in `DEMO_README.md`

2. **Application integration:**
   - Java/Spring Boot: See `SPRING_BOOT_DEMO.md`
   - Python/Flask: See `FLASK_DEMO.md`

3. **Demo secrets:**
   - Username: `demo_db_user`
   - Password: `demo_db_pwd`
   - Path: `secret/database/demo`

## Running the Demo Applications

After completing OpenBao setup, start the demo applications:

**Flask Application:**
```bash
cd flask-app
./run.sh
```
- Runs on: http://localhost:5000
- Test: `curl http://localhost:5000/db-credentials`

**Spring Boot Application:**
```bash
cd spring-boot-app
./run.sh
```
- Runs on: http://localhost:8080
- Test: `curl http://localhost:8080/db-credentials`

Both applications retrieve demo database credentials from OpenBao using AppRole authentication.

## Prerequisites

- Linux/macOS system
- Docker (for container deployment)
- Root/sudo access (for service deployment)
- curl, jq utilities
- Java 11+ (for Spring Boot demo)
- Python 3.8+ (for Flask demo)

## Security Notes

- Store unseal keys securely and separately
- Use restricted file permissions (600) for credential files
- Enable TLS in production environments
- Implement secret rotation policies
- Enable audit logging for compliance
