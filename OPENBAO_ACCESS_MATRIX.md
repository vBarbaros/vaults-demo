# OpenBao Access Control Matrix

## Authentication Methods & Policy Structure

### Access Control Components

| Component                   | Purpose                                | Scope           | Examples                          |
|-----------------------------|----------------------------------------|-----------------|-----------------------------------|
| **Authentication Method**   | How identity is verified               | System-wide     | Token, AppRole, LDAP, AWS IAM     |
| **Policy**                  | What actions are allowed               | Path-based      | read, write, create, delete, list |
| **Role**                    | Groups policies for specific use cases | Method-specific | app-role, user-role, service-role |
| **Token**                   | Temporary access credential            | Session-based   | client_token, periodic_token      |

## Complexity Matrix: Simple → Advanced

### Level 1: Basic Token Access
| Auth Method      | Credential Structure   | Policy Assignment        | Use Case            | Complexity  |
|------------------|------------------------|--------------------------|---------------------|-------------|
| **Root Token**   | `root_token`           | All policies (admin)     | Initial setup only  | ⭐           |
| **Static Token** | `client_token`         | Direct policy attachment | Development/testing | ⭐           |

```hcl
# Basic policy
path "secret/data/app/*" {
  capabilities = ["read"]
}
```

### Level 2: AppRole (Current Demo)
| Auth Method | Credential Structure    | Policy Assignment   | Use Case | Complexity   |
|-------------|-------------------------|---------------------|----------|--------------|
| **AppRole** | `role_id` + `secret_id` | Policy via role     | Machine-to-machine | ⭐⭐           |

```hcl
# AppRole configuration
auth "approle" {
  role "flask-app" {
    token_policies = ["db-policy"]
    token_ttl = "1h"
    token_max_ttl = "4h"
  }
}
```

### Level 3: User-Based Authentication
| Auth Method   | Credential Structure    | Policy Assignment      | Use Case         | Complexity   |
|---------------|-------------------------|------------------------|------------------|--------------|
| **Userpass**  | `username` + `password` | Policy via user/group  | Human users      | ⭐⭐           |
| **LDAP**      | `username` + `password` | Policy via LDAP groups | Enterprise users | ⭐⭐⭐          |

```hcl
# LDAP with group mapping
auth "ldap" {
  url = "ldap://ldap.company.com"
  groupdn = "ou=groups,dc=company,dc=com"
  groupattr = "cn"
  
  # Map LDAP groups to policies
  group "developers" {
    policies = ["dev-policy", "read-policy"]
  }
  group "admins" {
    policies = ["admin-policy"]
  }
}
```

### Level 4: Cloud Provider Integration
| Auth Method  | Credential Structure      | Policy Assignment       | Use Case        | Complexity |
|--------------|---------------------------|-------------------------|-----------------|------------|
| **AWS IAM**  | IAM role/instance profile | Policy via IAM role     | AWS resources   | ⭐⭐⭐ |
| **Azure AD** | Managed identity          | Policy via Azure groups | Azure resources | ⭐⭐⭐ |
| **GCP IAM**  | Service account           | Policy via GCP roles    | GCP resources   | ⭐⭐⭐ |

```hcl
# AWS IAM authentication
auth "aws" {
  role "ec2-role" {
    auth_type = "iam"
    bound_iam_role_arn = "arn:aws:iam::123456789012:role/MyRole"
    token_policies = ["ec2-policy"]
  }
}
```

### Level 5: Certificate-Based Authentication
| Auth Method   | Credential Structure      | Policy Assignment             | Use Case               | Complexity  |
|---------------|---------------------------|-------------------------------|------------------------|-------------|
| **TLS Cert**  | Client certificate        | Policy via cert metadata      | High-security services | ⭐⭐⭐⭐        |
| **PKI**       | Certificate + private key | Policy via certificate fields | Zero-trust networks    | ⭐⭐⭐⭐        |

```hcl
# Certificate authentication
auth "cert" {
  cert "web-cert" {
    certificate = "@/path/to/ca-cert.pem"
    policies = ["web-policy"]
    allowed_names = ["web.company.com"]
  }
}
```

### Level 6: Advanced Multi-Factor
| Auth Method    | Credential Structure   | Policy Assignment       | Use Case        | Complexity |
|----------------|------------------------|-------------------------|-----------------|------------|
| **OIDC/JWT**   | JWT token + claims     | Policy via token claims | SSO integration | ⭐⭐⭐⭐ |
| **Kubernetes** | Service account token  | Policy via namespace/SA | K8s workloads   | ⭐⭐⭐⭐ |

```hcl
# OIDC with role binding
auth "oidc" {
  oidc_discovery_url = "https://company.okta.com"
  oidc_client_id = "vault"
  
  role "developer" {
    bound_audiences = ["vault"]
    bound_claims = {
      "groups" = ["developers"]
    }
    user_claim = "email"
    policies = ["dev-policy"]
  }
}
```

## Policy Structure Complexity

### Basic Policies (Level 1-2)
```hcl
# Simple read-only access
path "secret/data/database/*" {
  capabilities = ["read"]
}

# Basic CRUD operations
path "secret/data/app/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

### Intermediate Policies (Level 3-4)
```hcl
# Conditional access with parameters
path "secret/data/users/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete"]
}

# Time-based access
path "secret/data/temp/*" {
  capabilities = ["read"]
  allowed_parameters = {
    "ttl" = ["1h", "2h", "4h"]
  }
}
```

### Advanced Policies (Level 5-6)
```hcl
# Complex templating with multiple conditions
path "secret/data/{{identity.entity.metadata.department}}/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete"]
  required_parameters = ["department", "project"]
  
  # Control based on token metadata
  control_group = {
    factor "managers" {
      identity {
        group_names = ["managers"]
      }
    }
  }
}

# Multi-path policy with inheritance
path "secret/data/shared/*" {
  capabilities = ["read", "list"]
}

path "secret/data/{{identity.groups.names}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
  min_wrapping_ttl = "5m"
  max_wrapping_ttl = "1h"
}
```

## Role Configuration Matrix

### AppRole Configurations

| Complexity       | Role Configuration                 | Security Features       | Use Case               |
|------------------|------------------------------------|-------------------------|------------------------|
| **Basic**        | Fixed role_id, rotating secret_id  | Basic TTL               | Single application     |
| **Intermediate** | CIDR restrictions, bind_secret_id  | IP filtering            | Multi-environment apps |
| **Advanced**     | Local secret_id, token_bound_cidrs | Network + local binding | High-security services |

```hcl
# Basic AppRole
vault write auth/approle/role/basic-app \
    token_policies="basic-policy" \
    token_ttl=1h \
    token_max_ttl=4h

# Intermediate AppRole with restrictions
vault write auth/approle/role/restricted-app \
    token_policies="app-policy" \
    token_ttl=30m \
    token_max_ttl=2h \
    bind_secret_id=true \
    secret_id_bound_cidrs="10.0.0.0/8,192.168.0.0/16"

# Advanced AppRole with local secret binding
vault write auth/approle/role/secure-app \
    token_policies="secure-policy" \
    token_ttl=15m \
    token_max_ttl=1h \
    bind_secret_id=true \
    local_secret_ids=true \
    secret_id_bound_cidrs="10.0.1.0/24" \
    token_bound_cidrs="10.0.1.0/24"
```

## Complete Access Control Examples

### Simple: Development Environment
```hcl
# Single policy for all developers
path "secret/data/dev/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Basic AppRole
vault write auth/approle/role/dev-app \
    token_policies="dev-policy" \
    token_ttl=8h
```

### Intermediate: Multi-Environment
```hcl
# Environment-specific policies
path "secret/data/{{identity.entity.metadata.environment}}/*" {
  capabilities = ["read", "list"]
}

path "secret/data/{{identity.entity.metadata.environment}}/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete"]
}

# Role with metadata binding
vault write auth/approle/role/app-{{env}} \
    token_policies="{{env}}-policy" \
    bind_secret_id=true \
    secret_id_bound_cidrs="{{env_cidr}}"
```

### Advanced: Zero-Trust Architecture
```hcl
# Multi-factor policy with control groups
path "secret/data/production/*" {
  capabilities = ["read"]
  
  control_group = {
    factor "approval" {
      identity {
        group_names = ["production-approvers"]
      }
    }
    
    factor "time_window" {
      identity {
        entity_metadata = {
          "shift" = ["day", "evening"]
        }
      }
    }
  }
}

# Certificate + AppRole combination
vault write auth/cert/certs/production-cert \
    certificate=@prod-ca.pem \
    policies="cert-base-policy"

vault write auth/approle/role/prod-service \
    token_policies="prod-service-policy" \
    bind_secret_id=true \
    local_secret_ids=true \
    secret_id_bound_cidrs="10.0.0.0/8" \
    token_bound_cidrs="10.0.0.0/8" \
    token_ttl=5m \
    token_max_ttl=15m
```

## Security Progression Summary

| Level | Authentication    | Authorization    | Credential Management   | Security Features            |
|-------|-------------------|------------------|-------------------------|------------------------------|
| **1** | Root/Static Token | Direct policy    | Manual                  | Basic access                 |
| **2** | AppRole           | Role-based       | Automated rotation      | TTL, secret_id               |
| **3** | User/LDAP         | Group-based      | Directory integration   | Group mapping                |
| **4** | Cloud IAM         | Cloud role-based | Cloud-native            | Instance identity            |
| **5** | Certificate       | PKI-based        | Certificate lifecycle   | Mutual TLS                   |
| **6** | OIDC/K8s          | Claims/SA-based  | External IdP            | Multi-factor, control groups |

This matrix shows the progression from simple token-based access to sophisticated zero-trust authentication with multiple verification factors and dynamic policy evaluation.
