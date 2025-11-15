# Application Startup Commands

## Prerequisites
1. Ensure OpenBao is running and configured (follow DEMO_README.md)
2. Make sure `.app-credentials` file exists in the root directory

## Flask Application
```bash
cd flask-app
./run.sh
```
- Runs on: http://localhost:5000
- Endpoints:
  - `/` - Home page
  - `/db-credentials` - Get database credentials from OpenBao
  - `/health` - Health check

## Spring Boot Application
```bash
cd spring-boot-app
./run.sh
```
- Runs on: http://localhost:8080
- Endpoints:
  - `/` - Home page
  - `/db-credentials` - Get database credentials from OpenBao
  - `/health` - Health check

## Testing
After starting either application, test the OpenBao integration:
```bash
# Test Flask app
curl http://localhost:5000/db-credentials

# Test Spring Boot app
curl http://localhost:8080/db-credentials
```

Both should return the demo database credentials stored in OpenBao.
