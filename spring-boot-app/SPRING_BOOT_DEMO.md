# Spring Boot OpenBao Integration Demo

This demo shows how to integrate a Spring Boot application with OpenBao for secure database credential management using **Gradle** as the build tool.

## Prerequisites

1. **OpenBao Setup Complete:**
   ```bash
   cd ../openbao-vault
   ./complete-docker-setup.sh
   ```

2. **Java 17+ and Gradle installed**
   ```bash
   # Install Gradle on macOS
   brew install gradle
   ```

3. **Spring Boot AppRole credentials available in `.app-credentials`**

## Project Structure

```
spring-boot-app/
├── SPRING_BOOT_DEMO.md          # This documentation  
├── build.gradle                 # Gradle build configuration
├── gradlew                      # Gradle wrapper script
├── gradle/wrapper/              # Gradle wrapper files
├── run.sh                      # Startup script (uses Gradle)
└── src/main/java/com/demo/
    ├── VaultDemoApplication.java  # Main Spring Boot class
    ├── VaultConfig.java          # Minimal configuration
    └── DemoController.java       # REST endpoints with direct OpenBao integration
```

## Current Status

✅ **Fully Working:**
- Spring Boot AppRole authentication with OpenBao
- Gradle build and compilation
- All REST endpoints functional
- Direct OpenBao integration using RestTemplate
- Credential loading from `.app-credentials`
- Clean port management

## How It Works

### 1. OpenBao Authentication
The Spring Boot app uses **AppRole authentication** with direct HTTP calls:
- **Role ID**: Public identifier for Spring Boot application  
- **Secret ID**: Private credential (rotated regularly)
- **Direct Integration**: Uses RestTemplate for HTTP calls to OpenBao API

### 2. Build Configuration (build.gradle)
```gradle
plugins {
    id 'org.springframework.boot' version '3.3.0'
    id 'io.spring.dependency-management' version '1.1.5'
    id 'java'
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.vault:spring-vault-core:3.1.1'
}
```

### 3. Direct OpenBao Integration
```java
@RestController
public class DemoController {
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    @GetMapping("/db-credentials")
    public Map<String, Object> getDbCredentials() {
        // 1. Get AppRole credentials from environment
        String roleId = System.getenv("ROLE_ID");      // Spring Boot Role ID
        String secretId = System.getenv("SECRET_ID");  // Spring Boot Secret ID
        
        // 2. Authenticate with OpenBao
        String authPayload = String.format("{\"role_id\":\"%s\",\"secret_id\":\"%s\"}", roleId, secretId);
        ResponseEntity<Map> authResponse = restTemplate.postForEntity(
            "http://127.0.0.1:8200/v1/auth/approle/login", authRequest, Map.class);
        
        // 3. Extract token and get secrets
        String token = ((Map) authResponse.getBody().get("auth")).get("client_token").toString();
        ResponseEntity<Map> secretResponse = restTemplate.exchange(
            "http://127.0.0.1:8200/v1/secret/data/database/demo",
            HttpMethod.GET, secretRequest, Map.class);
        
        return secretData;
    }
}
```

## Running the Demo

### Step 1: Start the Spring Boot Application
```bash
./run.sh
```

**What happens:**
- Loads Spring Boot AppRole credentials from `../openbao-vault/.app-credentials`
- Compiles the application with Gradle
- Starts Spring Boot server on http://localhost:8080

### Step 2: Test the Endpoints

**Home Page:**
```bash
curl http://localhost:8080/
```
**Response:**
```json
{
  "message": "Spring Boot OpenBao Demo",
  "status": "running"
}
```

**Database Credentials:**
```bash
curl http://localhost:8080/db-credentials
```
**Response:**
```json
{
  "password": "demo_db_pwd",
  "username": "demo_db_user"
}
```

**Health Check:**
```bash
curl http://localhost:8080/health
```
**Response:**
```json
{
  "status": "healthy"
}
```

## Gradle Commands

### Build and Run
```bash
# Using run script (recommended)
./run.sh

# Direct Gradle commands
gradle clean build          # Build the application
gradle bootRun              # Run the application
gradle compileJava          # Compile only
```

### Development
```bash
# Clean build
gradle clean

# Build without tests
gradle build -x test

# Run with debug
gradle bootRun --debug-jvm
```

## Troubleshooting

### Common Issues

**1. "No credentials found" error:**
```bash
# Solution: Run OpenBao setup first
cd ../openbao-vault
./complete-docker-setup.sh
```

**2. "Port 8080 already in use" error:**
```bash
# Quick solution: Kill process using port 8080
lsof -ti:8080 | xargs kill -9

# For any specific port (replace 8080 with your port)
lsof -ti:3000 | xargs kill -9   # Kill process on port 3000
lsof -ti:5000 | xargs kill -9   # Kill process on port 5000

# Safe version (asks before killing)
lsof -ti:8080 | xargs -p kill -9

# Step by step approach
lsof -i :8080                   # Find process using port
kill -9 <PID>                   # Kill specific process ID

# Alternative: Change port in application.yml
server:
  port: 8081                    # Use different port
```

**3. "Gradle not found" error:**
```bash
# Solution: Install Gradle
brew install gradle
# Or use wrapper: ./gradlew bootRun
```

**4. Build failures:**
```bash
# Solution: Clean and rebuild
gradle clean build
```

## Port Management

### Kill Process on Specific Port
When you encounter "Port already in use" errors, use these commands:

```bash
# Quick kill (most common)
lsof -ti:8080 | xargs kill -9

# For any port (replace with your port number)
lsof -ti:3000 | xargs kill -9   # Port 3000
lsof -ti:5000 | xargs kill -9   # Port 5000
lsof -ti:8080 | xargs kill -9   # Port 8080
lsof -ti:9000 | xargs kill -9   # Port 9000
```

### Safe Process Killing
```bash
# Ask before killing (safer)
lsof -ti:8080 | xargs -p kill -9

# Step by step approach
lsof -i :8080                   # 1. Find what's using the port
kill -9 <PID>                   # 2. Kill specific process ID
```

### Alternative Port Configuration
```yaml
# Change port in application.yml
server:
  port: 8081                    # Use port 8081 instead of 8080
```

### Check What's Using a Port
```bash
# See detailed information about port usage
lsof -i :8080

# Example output:
# COMMAND   PID   USER   FD   TYPE   DEVICE SIZE/OFF NODE NAME
# java    12345  user   123u  IPv6  0x1234      0t0  TCP *:8080 (LISTEN)
```

## Credential Configuration Options

The Spring Boot application supports multiple ways to provide OpenBao AppRole credentials:

### Option 1: Environment Variables (Current Default)
```bash
# Automatically set by run.sh script
export ROLE_ID=$SPRINGBOOT_ROLE_ID
export SECRET_ID=$SPRINGBOOT_SECRET_ID

# Used in Java code
String roleId = System.getenv("ROLE_ID");
String secretId = System.getenv("SECRET_ID");
```

### Option 2: application.yml with Environment Placeholders
```yaml
# src/main/resources/application.yml
openbao:
  url: http://127.0.0.1:8200
  role-id: ${ROLE_ID:}        # Gets from environment variable
  secret-id: ${SECRET_ID:}    # Gets from environment variable
```

### Option 3: Direct Values in application.yml
```yaml
# application.yml - NOT RECOMMENDED for production
openbao:
  url: http://127.0.0.1:8200
  role-id: "your-actual-role-id"
  secret-id: "your-actual-secret-id"
```

### Configuration Class Usage
The application includes an `OpenBaoConfig` class that reads from application.yml:

```java
@Component
@ConfigurationProperties(prefix = "openbao")
public class OpenBaoConfig {
    private String url;
    private String roleId;
    private String secretId;
    // getters and setters...
}
```

### Fallback Mechanism
The application uses a fallback approach:
1. **First**: Try to get credentials from `OpenBaoConfig` (application.yml)
2. **Fallback**: Use environment variables if config is empty
3. **Error**: Return error if neither source provides credentials

### Testing Configuration
Use the `/config` endpoint to check current configuration:
```bash
curl http://localhost:8080/config
```

**Response:**
```json
{
  "vault_url": "http://127.0.0.1:8200",
  "role_id_configured": true,
  "secret_id_configured": true,
  "env_role_id": "present",
  "env_secret_id": "present"
}
```

### Test Spring Boot AppRole Authentication
```bash
cd ../openbao-vault
source .app-credentials

# Test authentication manually
curl -s -X POST \
  -d "{\"role_id\":\"$SPRINGBOOT_ROLE_ID\",\"secret_id\":\"$SPRINGBOOT_SECRET_ID\"}" \
  http://127.0.0.1:8200/v1/auth/approle/login | jq '.auth.client_token'
```

### Check Credentials Loading
```bash
cd spring-boot-app
source ../openbao-vault/.app-credentials
echo "Spring Boot Role ID: ${SPRINGBOOT_ROLE_ID:0:8}..."
echo "Spring Boot Secret ID: ${SPRINGBOOT_SECRET_ID:0:8}..."
```

## Architecture Benefits

### Direct Integration Approach
- ✅ **No Spring Vault complexity** - Direct HTTP calls to OpenBao API
- ✅ **Full control** - Complete visibility into authentication flow
- ✅ **No URI configuration issues** - Bypasses Spring Vault URI problems
- ✅ **Simple debugging** - Easy to trace and troubleshoot
- ✅ **Lightweight** - Minimal dependencies

### Gradle Benefits
- ✅ **Faster builds** - Incremental compilation and caching
- ✅ **Better dependency management** - More flexible than Maven
- ✅ **Modern tooling** - Active development and features
- ✅ **Kotlin DSL support** - Can migrate to Kotlin DSL if needed

## Security Best Practices

### In This Demo
- ✅ AppRole authentication (no hardcoded credentials)
- ✅ Separate Spring Boot AppRole from Flask AppRole
- ✅ Environment variable injection
- ✅ Direct HTTP integration with proper error handling

### For Production
- 🔒 Enable TLS/HTTPS for OpenBao communication
- 🔒 Use Spring profiles for different environments
- 🔒 Implement secret caching with TTL
- 🔒 Add Spring Security integration
- 🔒 Implement token renewal logic
- 🔒 Add comprehensive error handling and retry logic

## Integration with Real Databases

```java
@Service
public class DatabaseService {
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    public DataSource createDataSource() {
        // Get credentials from OpenBao
        Map<String, Object> credentials = getDbCredentialsFromVault();
        
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(credentials.get("url").toString());
        config.setUsername(credentials.get("username").toString());
        config.setPassword(credentials.get("password").toString());
        
        return new HikariDataSource(config);
    }
    
    private Map<String, Object> getDbCredentialsFromVault() {
        // Implement the same authentication flow as in DemoController
        // Return database credentials from OpenBao
    }
}
```

## Migration from Maven

This project was converted from Maven to Gradle:

**Removed:**
- `pom.xml` → `build.gradle`
- `mvnw` → `gradlew`
- `.mvn/` → `gradle/wrapper/`
- `mvn spring-boot:run` → `gradle bootRun`

**Benefits of Migration:**
- Faster build times with Gradle's incremental compilation
- Better dependency management and conflict resolution
- More flexible build scripting capabilities
- Modern tooling and active development

## Next Steps

1. **Add database connection pooling** with retrieved credentials
2. **Implement secret rotation** with Spring scheduling
3. **Add Spring Security** for endpoint protection
4. **Implement token caching and renewal** for better performance
5. **Add comprehensive logging and monitoring**
6. **Create integration tests** with TestContainers

This demo provides a solid foundation for secure secret management in Spring Boot applications using OpenBao with modern Gradle tooling!
