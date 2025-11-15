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
# Solution: Kill process using port 8080
lsof -ti:8080 | xargs kill -9
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

## Verification

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
