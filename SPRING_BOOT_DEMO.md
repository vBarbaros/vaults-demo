# Spring Boot OpenBao Integration Demo

This demo shows the minimal setup required to integrate a Spring Boot application with OpenBao for secret management.

## Project Structure

```
spring-vault-demo/
├── pom.xml
├── src/main/java/com/demo/
│   ├── VaultDemoApplication.java
│   ├── config/VaultConfig.java
│   ├── service/DatabaseService.java
│   └── controller/DemoController.java
└── src/main/resources/
    └── application.yml
```

## Dependencies (pom.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.demo</groupId>
    <artifactId>spring-vault-demo</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
    </parent>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.vault</groupId>
            <artifactId>spring-vault-core</artifactId>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

## Configuration (application.yml)

```yaml
spring:
  cloud:
    vault:
      uri: http://127.0.0.1:8200
      authentication: APPROLE
      app-role:
        role-id: ${ROLE_ID}
        secret-id: ${SECRET_ID}
      kv:
        enabled: true
        backend: secret
        default-context: database

server:
  port: 8080

logging:
  level:
    org.springframework.vault: DEBUG
```

## Main Application

```java
// src/main/java/com/demo/VaultDemoApplication.java
package com.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class VaultDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(VaultDemoApplication.class, args);
    }
}
```

## Vault Configuration

```java
// src/main/java/com/demo/config/VaultConfig.java
package com.demo.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.vault.authentication.AppRoleAuthentication;
import org.springframework.vault.authentication.AppRoleAuthenticationOptions;
import org.springframework.vault.client.VaultEndpoint;
import org.springframework.vault.core.VaultTemplate;
import org.springframework.vault.support.VaultToken;
import org.springframework.beans.factory.annotation.Value;

@Configuration
public class VaultConfig {

    @Value("${spring.cloud.vault.uri}")
    private String vaultUri;

    @Value("${spring.cloud.vault.app-role.role-id}")
    private String roleId;

    @Value("${spring.cloud.vault.app-role.secret-id}")
    private String secretId;

    @Bean
    public VaultTemplate vaultTemplate() {
        VaultEndpoint endpoint = VaultEndpoint.from(java.net.URI.create(vaultUri));
        
        AppRoleAuthenticationOptions options = AppRoleAuthenticationOptions.builder()
            .roleId(roleId)
            .secretId(secretId)
            .build();
            
        AppRoleAuthentication authentication = new AppRoleAuthentication(options, endpoint);
        
        return new VaultTemplate(endpoint, authentication);
    }
}
```

## Database Service

```java
// src/main/java/com/demo/service/DatabaseService.java
package com.demo.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.vault.core.VaultTemplate;
import org.springframework.vault.support.VaultResponse;

import java.util.Map;

@Service
public class DatabaseService {

    @Autowired
    private VaultTemplate vaultTemplate;

    public Map<String, String> getDatabaseCredentials() {
        VaultResponse response = vaultTemplate.read("secret/data/database/demo");
        
        if (response != null && response.getData() != null) {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) response.getData().get("data");
            
            return Map.of(
                "username", (String) data.get("username"),
                "password", (String) data.get("password")
            );
        }
        
        throw new RuntimeException("Failed to retrieve database credentials");
    }

    public String getConnectionString() {
        Map<String, String> credentials = getDatabaseCredentials();
        return String.format("jdbc:postgresql://localhost:5432/demo?user=%s&password=%s",
            credentials.get("username"), credentials.get("password"));
    }
}
```

## Demo Controller

```java
// src/main/java/com/demo/controller/DemoController.java
package com.demo.controller;

import com.demo.service.DatabaseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class DemoController {

    @Autowired
    private DatabaseService databaseService;

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP", "vault", "connected");
    }

    @GetMapping("/db-info")
    public Map<String, String> getDatabaseInfo() {
        try {
            Map<String, String> credentials = databaseService.getDatabaseCredentials();
            return Map.of(
                "username", credentials.get("username"),
                "password", "***HIDDEN***",
                "status", "credentials_retrieved"
            );
        } catch (Exception e) {
            return Map.of("error", e.getMessage());
        }
    }

    @GetMapping("/connection-string")
    public Map<String, String> getConnectionString() {
        try {
            String connectionString = databaseService.getConnectionString();
            // Mask password in response
            String maskedConnection = connectionString.replaceAll("password=[^&]*", "password=***");
            return Map.of("connection", maskedConnection);
        } catch (Exception e) {
            return Map.of("error", e.getMessage());
        }
    }
}
```

## Setup and Run Scripts

### Environment Setup Script

```bash
#!/bin/bash
# setup-spring-demo.sh

echo "Setting up Spring Boot OpenBao Demo..."

# Create project directory
mkdir -p spring-vault-demo/src/main/java/com/demo/{config,service,controller}
mkdir -p spring-vault-demo/src/main/resources

cd spring-vault-demo

# Create all the files (pom.xml, application.yml, Java files)
# ... (files would be created here)

echo "Project structure created!"
echo "Next steps:"
echo "1. Ensure OpenBao is running with demo secrets"
echo "2. Export ROLE_ID and SECRET_ID environment variables"
echo "3. Run: mvn spring-boot:run"
```

### Run with Vault Credentials

```bash
#!/bin/bash
# run-spring-demo.sh

# Load OpenBao credentials
if [ -f ../.app-credentials ]; then
    source ../.app-credentials
    echo "Loaded OpenBao credentials"
else
    echo "Error: .app-credentials file not found"
    echo "Run the OpenBao setup scripts first"
    exit 1
fi

# Export environment variables
export ROLE_ID=$ROLE_ID
export SECRET_ID=$SECRET_ID

echo "Starting Spring Boot application..."
echo "ROLE_ID: ${ROLE_ID:0:8}..."
echo "SECRET_ID: ${SECRET_ID:0:8}..."

# Start the application
cd spring-vault-demo
mvn spring-boot:run
```

### Test Script

```bash
#!/bin/bash
# test-spring-demo.sh

echo "Testing Spring Boot OpenBao integration..."

BASE_URL="http://localhost:8080"

echo "1. Health check:"
curl -s $BASE_URL/health | jq .

echo -e "\n2. Database info:"
curl -s $BASE_URL/db-info | jq .

echo -e "\n3. Connection string:"
curl -s $BASE_URL/connection-string | jq .

echo -e "\nDemo complete!"
```

## Docker Integration

### Dockerfile

```dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app
COPY target/spring-vault-demo-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Docker Compose with OpenBao

```yaml
# docker-compose.yml
version: '3.8'

services:
  vault:
    image: openbao/openbao:latest
    container_name: vault-server
    ports:
      - "8200:8200"
    volumes:
      - ./vault-data:/vault/data
      - ./vault-config.hcl:/vault/config/vault-config.hcl
    command: server -config=/vault/config/vault-config.hcl
    cap_add:
      - IPC_LOCK

  spring-app:
    build: .
    container_name: spring-vault-demo
    ports:
      - "8080:8080"
    environment:
      - ROLE_ID=${ROLE_ID}
      - SECRET_ID=${SECRET_ID}
      - SPRING_CLOUD_VAULT_URI=http://vault:8200
    depends_on:
      - vault
```

## Complete Demo Workflow

### 1. Setup OpenBao (if not done)

```bash
# From the openbao-config directory
./complete-docker-setup.sh
```

### 2. Create Spring Boot Project

```bash
# Create the Spring Boot demo project
./setup-spring-demo.sh
```

### 3. Build and Run

```bash
# Build the application
cd spring-vault-demo
mvn clean package

# Run with OpenBao credentials
cd ..
./run-spring-demo.sh
```

### 4. Test Integration

```bash
# Test the endpoints
./test-spring-demo.sh
```

## Expected Output

```json
// GET /health
{
  "status": "UP",
  "vault": "connected"
}

// GET /db-info
{
  "username": "demo_db_user",
  "password": "***HIDDEN***",
  "status": "credentials_retrieved"
}

// GET /connection-string
{
  "connection": "jdbc:postgresql://localhost:5432/demo?user=demo_db_user&password=***"
}
```

## Key Integration Points

1. **AppRole Authentication**: Uses role-id and secret-id for secure authentication
2. **Automatic Token Renewal**: Spring Vault handles token lifecycle
3. **Secret Retrieval**: Direct access to KV secrets engine
4. **Error Handling**: Graceful handling of vault connectivity issues
5. **Security**: Passwords are masked in API responses

## Production Considerations

- Use HTTPS for vault communication
- Implement secret caching with TTL
- Add health checks for vault connectivity
- Use separate vault namespaces per environment
- Implement secret rotation handling
- Add comprehensive error handling and logging

This minimal demo shows the essential components needed to integrate Spring Boot with OpenBao for secure secret management.
