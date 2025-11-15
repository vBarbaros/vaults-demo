# OpenBao Vaults Demo

A comprehensive demonstration project showing how to set up and integrate OpenBao (open-source HashiCorp Vault fork) for secrets management across different deployment scenarios and application frameworks.

## Why OpenBao?

OpenBao Vault is free from complex licensing restrictions and can be used inside an enterprise with no contracts or ongoing fees, while HashiCorp Vault's licensing now places limits on certain types of enterprise usage due to its adoption of the Business Source License (BSL).[1][2][3]

### HashiCorp Vault License Details

- Since August 2023, HashiCorp Vault uses the Business Source License (BSL 1.1).[4][5][6]
- BSL allows internal and personal use within organizations, but restricts users from offering Vault as a competitive SaaS product or as part of a competitive offering versus HashiCorp.[6][7]
- Enterprises that do not intend to compete with HashiCorp commercially (such as SaaS hosting) can generally use Vault internally for free, but the license is not OSI-approved open source, and some use cases (especially externalized services) could fall afoul of restrictions.[7]

### OpenBao Vault License Details

- OpenBao is a community-led fork of HashiCorp Vault, primarily created in response to the BSL shift.
- OpenBao is licensed under the Mozilla Public License 2.0 (MPL 2.0), which is OSI-approved and truly open source.[3][1]
- The MPL 2.0 license allows enterprise use, modification, and distribution, including commercial deployments, with none of the competitive usage restrictions found in HashiCorp's BSL.[3]
- OpenBao is positioning itself as fully free for enterprise use, including features formerly in Vault's paid editions.[2]

### Comparison Table

| Feature                          | HashiCorp Vault                   | OpenBao Vault                        |
|----------------------------------|-----------------------------------|--------------------------------------|
| License type                     | BSL 1.1 (source-available) [4][5] | MPL 2.0 (OSI open source) [1][3]     |
| Free for internal enterprise use | Yes, with limitations [5][7]      | Yes, unconditionally [3]             |
| Free for SaaS/competitive use    | No [6]                            | Yes [1][3]                           |
| Open source recognized by OSI    | No [7]                            | Yes [1][3]                           |
| Paid enterprise features         | Yes [8][2]                        | No; all enterprise features free [2] |

### Recommendation

- For maximum legal safety and guaranteed open-source compliance with no fees or contracts, OpenBao Vault is the preferred choice for enterprises, especially if vendor neutrality or future-proof licensing is a concern.[1][2][3]
- HashiCorp Vault may still be usable for internal non-SaaS usage in some enterprise settings, but licensing restrictions make it less attractive where full freedom is required.[5][6][7]

## Author

**vBarbaros** (victor.barbarosh@gmail.com)

## Contents

This repository contains:

- **DEMO_README.md** - Complete OpenBao setup guide with two deployment options:
  - Docker container deployment (isolated, portable)
  - System service deployment (native performance)
- **SPRING_BOOT_DEMO.md** - Spring Boot application integration with OpenBao
- **flask-app/** - Working Flask application with OpenBao integration
  - **FLASK_DEMO.md** - Flask integration guide and documentation
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
   - Python/Flask: See `flask-app/FLASK_DEMO.md`

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

## References

[1]: https://www.theregister.com/2023/12/08/hashicorp_openbao_fork/
[2]: https://news.ycombinator.com/item?id=44133909
[3]: https://infisical.com/blog/open-source-secrets-management-devops
[4]: https://www.hashicorp.com/en/blog/hashicorp-adopts-business-source-license
[5]: https://invgate.com/itdb/hashicorp-vault
[6]: https://www.netnetweb.com/content/blog/hashicorp-starts-charging-for-previously-free-open-source-code
[7]: https://www.digitalcorner-wavestone.com/2023/09/how-hashicorps-license-change-impacts-organizations/
[8]: https://infisical.com/blog/hashicorp-vault-pricing
