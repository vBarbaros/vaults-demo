package com.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.vault.core.VaultTemplate;
import org.springframework.vault.support.VaultResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
public class DemoController {
    
    @Autowired
    private VaultTemplate vaultTemplate;
    
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
            VaultResponse response = vaultTemplate.read("secret/data/database/demo");
            return response != null ? response.getData() : new HashMap<>();
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", e.getMessage());
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
