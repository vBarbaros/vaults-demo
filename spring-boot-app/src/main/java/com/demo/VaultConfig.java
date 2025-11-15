package com.demo;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.vault.authentication.AppRoleAuthentication;
import org.springframework.vault.authentication.AppRoleAuthenticationOptions;
import org.springframework.vault.client.VaultEndpoint;
import org.springframework.vault.core.VaultTemplate;

@Configuration
public class VaultConfig {
    
    @Bean
    public VaultTemplate vaultTemplate() {
        String roleId = System.getenv("ROLE_ID");
        String secretId = System.getenv("SECRET_ID");
        
        if (roleId != null && secretId != null) {
            AppRoleAuthenticationOptions options = AppRoleAuthenticationOptions.builder()
                .roleId(roleId)
                .secretId(secretId)
                .build();
            
            return new VaultTemplate(
                VaultEndpoint.create("127.0.0.1", 8200),
                new AppRoleAuthentication(options)
            );
        }
        
        return new VaultTemplate(VaultEndpoint.create("127.0.0.1", 8200));
    }
}
