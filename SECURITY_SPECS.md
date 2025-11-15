# Security Specifications

## Overview

This document outlines the security specifications and best practices implemented in the OpenBao Vaults Demo project for secrets management and application integration.

## Security Architecture

### OpenBao (Vault) Security Model

**Encryption at Rest:**
- All secrets stored using AES-256-GCM encryption
- Master key protected by Shamir's Secret Sharing (5 shares, 3 threshold)
- Configurable storage backends for enterprise scalability

**Storage Backend Options:**

*Current Demo Configuration:*
- **File Storage:** Local filesystem storage for development/testing

*Enterprise Storage Backends:*

**🆓 Free & Open-Source Options:**

**PostgreSQL:** ⭐ **RECOMMENDED FREE OPTION**
- High availability with replication support
- ACID compliance for data consistency
- Built-in backup and point-in-time recovery
- SSL/TLS encryption in transit
- Configuration: `storage "postgresql" { connection_url = "postgres://..." }`
- **License:** PostgreSQL License (BSD-style)

**MySQL:**
- Mature, widely adopted database platform
- Master-slave replication for high availability
- InnoDB storage engine with crash recovery
- Encrypted tablespaces support
- Configuration: `storage "mysql" { connection_url = "mysql://..." }`
- **License:** GPL v2 (Community Edition)

**Consul:**
- Distributed key-value store with clustering
- Built-in service discovery and health checking
- Multi-datacenter replication
- Gossip protocol for node communication
- Configuration: `storage "consul" { address = "127.0.0.1:8500" }`
- **License:** Mozilla Public License 2.0

**etcd:**
- Distributed, reliable key-value store
- Raft consensus algorithm for consistency
- Watch API for real-time updates
- TLS client certificate authentication
- Configuration: `storage "etcd" { endpoints = "https://etcd1:2379" }`
- **License:** Apache License 2.0

**CockroachDB (Core):**
- Distributed SQL database with ACID guarantees
- Automatic replication and failover
- Geo-distributed deployments
- Encryption at rest and in transit
- Configuration: `storage "cockroachdb" { connection_url = "postgresql://..." }`
- **License:** Apache License 2.0 (Core version)

**Cassandra:**
- Distributed NoSQL database for large-scale data
- Linear scalability and fault tolerance
- Tunable consistency levels
- Built-in security features
- Configuration: `storage "cassandra" { hosts = "cassandra1,cassandra2" }`
- **License:** Apache License 2.0

**💰 Commercial/Managed Cloud Options:**

**DynamoDB (AWS):**
- Fully managed NoSQL database service
- Automatic scaling and high availability
- Encryption at rest with AWS KMS
- Point-in-time recovery and backups
- Configuration: `storage "dynamodb" { table = "vault-data" }`
- **Cost:** Pay-per-use AWS service

**Azure Storage Account:**
- Managed cloud storage with geo-replication
- Azure Active Directory integration
- Encryption with customer-managed keys
- Immutable blob storage for compliance
- Configuration: `storage "azure" { accountName = "vaultdata" }`
- **Cost:** Pay-per-use Azure service

**Google Cloud Storage:**
- Object storage with global edge caching
- Customer-managed encryption keys (CMEK)
- Uniform bucket-level access control
- Audit logging with Cloud Audit Logs
- Configuration: `storage "gcs" { bucket = "vault-backend" }`
- **Cost:** Pay-per-use GCP service

**Enterprise Recommendations:**

**🆓 Cost-Effective Open-Source Setup:**
- **Primary:** PostgreSQL with streaming replication (FREE)
- **Service Discovery:** Consul cluster (FREE)
- **Monitoring:** Prometheus + Grafana (FREE)
- **Load Balancer:** NGINX or HAProxy (FREE)

**💰 Hybrid Cloud Strategy:**
- **AWS:** DynamoDB + RDS PostgreSQL (MANAGED)
- **Azure:** Azure Storage + Azure Database for PostgreSQL (MANAGED)
- **GCP:** Cloud Storage + Cloud SQL PostgreSQL (MANAGED)
- **On-Premises:** PostgreSQL + Consul (FREE)

**🏢 Enterprise Scale (Free Options):**
- **High Availability:** PostgreSQL cluster with Patroni (FREE)
- **Distributed:** CockroachDB Core multi-region (FREE)
- **Large Scale:** Cassandra cluster (FREE)
- **Service Mesh:** Consul Connect (FREE)

**Performance Considerations:**
- **Read-Heavy:** PostgreSQL read replicas (FREE) or Consul (FREE)
- **Write-Heavy:** CockroachDB Core (FREE) or DynamoDB (PAID)
- **Large Scale:** Cassandra (FREE) with multiple data centers
- **Low Latency:** Local PostgreSQL (FREE) with SSD storage

**Compliance Requirements:**
- **SOC 2:** PostgreSQL with encrypted storage (FREE)
- **PCI-DSS:** PostgreSQL + proper access controls (FREE)
- **HIPAA:** PostgreSQL with encryption at rest (FREE)
- **GDPR:** Regional PostgreSQL deployment (FREE)

**Authentication Methods:**
- AppRole authentication for machine-to-machine access
- Separate roles for Flask and Spring Boot applications
- Token-based access with configurable TTL (Time To Live)

**Authorization:**
- Policy-based access control (PBAC)
- Least-privilege principle implementation
- Path-based secret access restrictions

## Credential Management

### AppRole Configuration

**Flask Application Role:**
- Role ID: Public identifier (safe to store in configuration)
- Secret ID: Private credential (rotated regularly)
- Token TTL: 1 hour
- Token Max TTL: 4 hours
- Policy: `db-policy` (database secrets access only)

**Spring Boot Application Role:**
- Role ID: Public identifier (safe to store in configuration)
- Secret ID: Private credential (rotated regularly)
- Token TTL: 1 hour
- Token Max TTL: 4 hours
- Policy: `db-policy` (database secrets access only)

### Secret Storage

**Database Credentials:**
- Path: `secret/database/demo`
- Versioned storage (KV v2 engine)
- Encrypted at rest
- Access logged and auditable

**Credential Rotation:**
- JSON-based credential management (`db-credentials-in-use.json`)
- Automated timestamp tracking
- Zero-downtime credential updates
- Applications fetch credentials dynamically

## Enterprise Deployment Architecture

### High Availability Configuration

**Multi-Node Cluster:**
```hcl
# Primary Node Configuration
storage "postgresql" {
  connection_url = "postgres://vault:password@postgres-primary:5432/vault?sslmode=require"
  ha_enabled     = "true"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/vault/tls/vault.crt"
  tls_key_file  = "/vault/tls/vault.key"
}

seal "awskms" {
  region     = "us-west-2"
  kms_key_id = "alias/vault-unseal-key"
}

ui = true
cluster_addr = "https://vault-1:8201"
api_addr = "https://vault-1:8200"
```

**Load Balancer Configuration:**
- **AWS ALB:** Application Load Balancer with SSL termination
- **NGINX:** Reverse proxy with health checks
- **HAProxy:** TCP load balancing for Vault cluster
- **Consul Connect:** Service mesh integration

### Storage Backend Comparison

| Backend                 | Availability | Consistency | Performance | Complexity | License            | Cost       |
|-------------------------|--------------|-------------|-------------|------------|--------------------|------------|
| **PostgreSQL** 🆓       | High         | Strong      | High        | Medium     | PostgreSQL (BSD)   | **FREE**   |
| **MySQL** 🆓            | High         | Strong      | High        | Medium     | GPL v2             | **FREE**   |
| **Consul** 🆓           | High         | Strong      | Medium      | High       | MPL 2.0            | **FREE**   |
| **etcd** 🆓             | High         | Strong      | High        | Medium     | Apache 2.0         | **FREE**   |
| **CockroachDB Core** 🆓 | Very High    | Strong      | High        | High       | Apache 2.0         | **FREE**   |
| **Cassandra** 🆓        | Very High    | Tunable     | Very High   | Very High  | Apache 2.0         | **FREE**   |
| **DynamoDB** 💰         | Very High    | Eventual    | Very High   | Low        | Proprietary        | **PAID**   |
| **Azure Storage** 💰    | Very High    | Strong      | High        | Low        | Proprietary        | **PAID**   |
| **GCS** 💰              | Very High    | Strong      | High        | Low        | Proprietary        | **PAID**   |

**🆓 = Free & Open-Source**  
**💰 = Commercial/Managed Service**

**Legend:**
- **License Types:**
  - **PostgreSQL (BSD):** Very permissive, commercial use allowed
  - **GPL v2:** Copyleft license, requires source disclosure for modifications
  - **MPL 2.0:** Mozilla Public License, file-level copyleft
  - **Apache 2.0:** Permissive license with patent protection
  - **Proprietary:** Commercial license, usage fees apply

### Disaster Recovery Strategies

**Cross-Region Replication:**
- **PostgreSQL:** Streaming replication to secondary region
- **DynamoDB:** Global tables with multi-region writes
- **Consul:** WAN federation across data centers
- **Cloud Storage:** Cross-region bucket replication

**Backup Strategies:**
- **Automated Snapshots:** Daily encrypted backups
- **Point-in-Time Recovery:** Transaction log shipping
- **Cross-Cloud Backup:** Multi-cloud storage redundancy
- **Offline Backup:** Air-gapped secure storage

### Monitoring and Observability

**Database Metrics:**
- Connection pool utilization
- Query performance and latency
- Storage capacity and growth
- Replication lag monitoring

**Vault Metrics:**
- Request rate and response times
- Authentication success/failure rates
- Secret access patterns
- Seal/unseal events

**Alerting Thresholds:**
- Database connection failures
- Replication lag > 5 seconds
- Storage capacity > 80%
- Failed authentication rate > 10/minute

### Database Policy (`db-policy`)
```hcl
path "secret/data/database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

**Scope:** Grants full access to database secrets under `secret/database/*` path
**Applications:** Both Flask and Spring Boot applications
**Principle:** Least-privilege access to required secrets only

## File Security

### Protected Files
- `.vault-keys.json` - Unseal keys and root token
- `.app-credentials` - AppRole credentials
- `db-credentials-in-use.json` - Database credentials
- `vault-data/` - Encrypted vault storage
- `*.pem`, `*.key`, `*.crt` - Certificate files

### Vault Keys Management (`.vault-keys.json`)

**Critical Security Requirements:**

The `.vault-keys.json` file contains the most sensitive credentials in the entire system:
- **Unseal Keys:** Required to unseal the vault after restarts
- **Root Token:** Provides administrative access to all vault operations

**Secure Storage Strategy:**

1. **Password Manager Storage:**
   ```bash
   # Store in enterprise password manager
   # - Store each unseal key as separate secure note
   # - Store root token as separate secure note
   # - Include vault instance identifier in notes
   ```

2. **File System Management:**
   ```bash
   # Remove from filesystem after storing in password manager
   rm .vault-keys.json
   
   # When needed, create temporary file with restricted permissions
   touch .vault-keys.json
   chmod 600 .vault-keys.json
   # Populate from password manager, use, then delete immediately
   ```

3. **Access Control:**
   ```bash
   # Only create when needed for vault operations
   # Multiple authorized personnel should have access
   # Use secure channels for sharing (encrypted communication)
   ```

**When Vault Restart is Required:**

**Automatic Restart Scenarios:**
- System reboot or shutdown
- Docker container restart
- Service crash or failure
- Memory exhaustion or system resource issues
- Process termination (manual or automatic)

**Manual Restart Scenarios:**
- Configuration changes requiring restart
- Certificate updates or TLS configuration changes
- Storage backend modifications
- Plugin installations or updates
- Performance tuning requiring service restart
- Security incident response (seal and restart)
- Maintenance windows and updates

**Emergency Restart Procedures:**
1. **Retrieve credentials from password manager**
2. **Create temporary `.vault-keys.json` with proper permissions**
3. **Unseal vault using stored keys**
4. **Verify vault functionality**
5. **Immediately delete `.vault-keys.json` file**
6. **Document restart event in audit log**

**Multi-Person Unsealing (Production):**
```bash
# Distribute unseal keys among multiple authorized personnel
# Require minimum threshold (e.g., 3 of 5 keys) for unsealing
# Each person provides their key during restart process
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
# Vault automatically unseals when threshold is met
```

### File Permissions
```bash
# Recommended permissions
chmod 600 .vault-keys.json
chmod 600 .app-credentials
chmod 600 db-credentials-in-use.json
chmod 700 vault-data/
```

### Version Control Protection
All sensitive files are excluded via `.gitignore`:
```gitignore
.vault-keys.json
.app-credentials
db-credentials-in-use.json
vault-data/
*.pem
*.key
*.crt
```

## Network Security

### Communication Protocols

**Demo Environment:**
- HTTP (port 8200) - For demonstration purposes only
- Unencrypted communication between applications and OpenBao

**Production Requirements:**
- HTTPS/TLS 1.3 minimum
- Certificate-based authentication
- Network segmentation and firewall rules
- VPN or private network access

### Port Configuration
- OpenBao: 8200 (HTTP in demo, HTTPS in production)
- Flask App: 5000
- Spring Boot App: 8080

## Authentication Flow

### Application Authentication Process

1. **Credential Loading:**
   - Applications load Role ID and Secret ID from environment variables
   - Credentials sourced from `.app-credentials` file
   - Fallback to configuration files if environment variables unavailable

2. **Token Acquisition:**
   ```bash
   POST /v1/auth/approle/login
   {
     "role_id": "<role_id>",
     "secret_id": "<secret_id>"
   }
   ```

3. **Secret Retrieval:**
   ```bash
   GET /v1/secret/data/database/demo
   Headers: X-Vault-Token: <client_token>
   ```

4. **Token Lifecycle:**
   - Initial TTL: 1 hour
   - Maximum TTL: 4 hours
   - Automatic renewal by applications
   - Revocation on application shutdown

## Security Best Practices

### Development Environment

**Implemented:**
- ✅ Separate AppRoles per application
- ✅ Policy-based access control
- ✅ Credential rotation capability
- ✅ File permission restrictions
- ✅ Version control exclusions
- ✅ Token TTL limitations

**Recommended Enhancements:**
- 🔒 Enable audit logging
- 🔒 Implement secret versioning
- 🔒 Add credential expiration alerts
- 🔒 Enable MFA for administrative access

### Production Environment

**Critical Requirements:**
- 🔒 **TLS/HTTPS:** Enable TLS 1.3 for all communications
- 🔒 **Certificate Management:** Use proper CA-signed certificates
- 🔒 **Network Security:** Implement network segmentation
- 🔒 **Key Management:** Use HSM or cloud KMS for master keys
- 🔒 **Monitoring:** Enable comprehensive audit logging
- 🔒 **Backup:** Implement encrypted backup strategies
- 🔒 **Access Control:** Implement RBAC with MFA
- 🔒 **Secret Rotation:** Automated credential rotation
- 🔒 **Compliance:** Meet regulatory requirements (SOC2, PCI-DSS, etc.)

## Threat Model

### Identified Threats

**High Risk:**
- Unauthorized access to unseal keys
- Compromise of root token
- Network interception (mitigated by TLS in production)
- Insider threats with administrative access

**Medium Risk:**
- Application credential compromise
- File system access to vault data
- Container escape (Docker deployment)

**Low Risk:**
- Brute force attacks on sealed vault
- Side-channel attacks on encryption

### Mitigation Strategies

**Access Control:**
- Multi-person unsealing process
- Regular credential rotation
- Principle of least privilege
- Audit logging and monitoring

**Infrastructure:**
- Network segmentation
- Container security hardening
- Regular security updates
- Backup and disaster recovery

## Compliance Considerations

### Data Protection
- Encryption at rest and in transit
- Access logging and audit trails
- Data retention policies
- Secure deletion procedures

### Regulatory Alignment
- **GDPR:** Data protection and privacy controls
- **SOC 2:** Security and availability controls
- **PCI-DSS:** Payment card data protection (if applicable)
- **HIPAA:** Healthcare data protection (if applicable)

## Incident Response

### Security Incident Procedures

**Immediate Actions:**
1. Seal the vault to prevent further access
2. Revoke compromised tokens and credentials
3. Isolate affected systems
4. Preserve logs and evidence

**Recovery Actions:**
1. Assess scope of compromise
2. Rotate all potentially affected credentials
3. Update access policies as needed
4. Restore from secure backups if necessary

**Post-Incident:**
1. Conduct security review
2. Update security procedures
3. Implement additional controls
4. Document lessons learned

## Security Testing

### Recommended Testing Procedures

**Regular Assessments:**
- Vulnerability scanning
- Penetration testing
- Code security reviews
- Configuration audits

**Automated Testing:**
- Secret scanning in CI/CD pipelines
- Dependency vulnerability checks
- Infrastructure as Code security scanning
- Container image security scanning

## Monitoring and Alerting

### Security Metrics

**Access Monitoring:**
- Failed authentication attempts
- Unusual access patterns
- Token usage anomalies
- Policy violations

**System Monitoring:**
- Vault seal/unseal events
- Configuration changes
- Performance anomalies
- Storage capacity alerts

### Alert Thresholds
- Multiple failed authentications (>5 in 5 minutes)
- Vault seal events
- Root token usage
- Policy modifications
- Unusual secret access patterns

## Conclusion

This security specification provides a foundation for secure secrets management using OpenBao. While the demo environment prioritizes ease of use and learning, production deployments must implement the enhanced security measures outlined in this document.

Regular security reviews and updates to these specifications are essential to maintain security posture as the system evolves and new threats emerge.
