package com.demo;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
public class DemoController {
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    @GetMapping("/")
    public Map<String, String> home() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Spring Boot OpenBao Demo");
        response.put("status", "running");
        return response;
    }
    
    @GetMapping("/db-credentials")
    public Map<String, Object> getDbCredentials() {
        try {
            // Get AppRole credentials from environment
            String roleId = System.getenv("ROLE_ID");
            String secretId = System.getenv("SECRET_ID");
            
            if (roleId == null || secretId == null) {
                Map<String, Object> error = new HashMap<>();
                error.put("error", "AppRole credentials not found in environment");
                return error;
            }
            
            // Authenticate with OpenBao using AppRole
            String authPayload = String.format("{\"role_id\":\"%s\",\"secret_id\":\"%s\"}", roleId, secretId);
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<String> authRequest = new HttpEntity<>(authPayload, headers);
            
            ResponseEntity<Map> authResponse = restTemplate.postForEntity(
                "http://127.0.0.1:8200/v1/auth/approle/login", authRequest, Map.class);
            
            if (authResponse.getBody() == null || authResponse.getBody().get("auth") == null) {
                Map<String, Object> error = new HashMap<>();
                error.put("error", "Authentication failed");
                return error;
            }
            
            // Extract token
            Map auth = (Map) authResponse.getBody().get("auth");
            String token = auth.get("client_token").toString();
            
            // Get secrets using the token
            HttpHeaders secretHeaders = new HttpHeaders();
            secretHeaders.set("X-Vault-Token", token);
            HttpEntity<String> secretRequest = new HttpEntity<>(secretHeaders);
            
            ResponseEntity<Map> secretResponse = restTemplate.exchange(
                "http://127.0.0.1:8200/v1/secret/data/database/demo",
                org.springframework.http.HttpMethod.GET,
                secretRequest,
                Map.class);
            
            if (secretResponse.getBody() != null && secretResponse.getBody().get("data") != null) {
                Map data = (Map) secretResponse.getBody().get("data");
                if (data.get("data") != null) {
                    return (Map<String, Object>) data.get("data");
                }
            }
            
            Map<String, Object> error = new HashMap<>();
            error.put("error", "No secrets found");
            return error;
            
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("type", e.getClass().getSimpleName());
            return error;
        }
    }
    
    @GetMapping("/health")
    public Map<String, String> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "healthy");
        return response;
    }
}
