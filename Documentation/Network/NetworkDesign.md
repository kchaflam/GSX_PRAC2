# Network Design — IP Addressing & Segmentation

## Overview

The network is designed around the principle of least privilege — each environment and team only has access to what it strictly needs. Separating environments into different network segments reduces the blast radius of a misconfiguration or a compromised host: a problem in development cannot directly reach production, and external partners are isolated from internal systems.

---

## IP Addressing Plan

The entire organization uses the `10.0.0.0/16` block, which provides 65,534 usable addresses — more than enough room to grow. This is subdivided into `/24` subnets per environment, each providing 254 usable addresses.

| Subnet | CIDR | Purpose |
|--------|------|---------|
| Development | `10.0.1.0/24` | Developer workloads and testing |
| Staging | `10.0.2.0/24` | Pre-production validation |
| Production | `10.0.3.0/24` | Live services |
| DMZ | `10.0.4.0/24` | Public-facing services (Nginx, load balancers) |
| Partners | `10.0.10.0/24` | External partner and contractor access |
| Management | `10.0.20.0/24` | Internal tooling, monitoring, CI/CD runners |

### Why /24 per environment?

A `/24` gives 254 usable addresses per subnet, which is sufficient for each environment at GreenDevCorp's current size. Using the same prefix length across all subnets keeps the addressing plan consistent and easy to reason about. The large gaps between subnet numbers (1, 2, 3, 10, 20) leave room to add new subnets in the future without having to renumber existing ones.

### Why 10.0.0.0/16?

Private address ranges (RFC 1918) are not routable on the public internet, which means they cannot be accidentally reached from outside without going through a controlled entry point. Using a `/16` as the parent block keeps all organization traffic within a single, clearly defined range and makes routing rules simpler.

---

## Security Boundaries

### What traffic is allowed

- Development can reach the internet for package downloads and external APIs
- Staging can reach production read-only endpoints for data seeding if needed
- DMZ can receive traffic from the internet on ports 80 and 443 only
- DMZ can forward traffic to production services on defined internal ports
- Partners can reach specific DMZ endpoints only, with no access to internal subnets
- Management subnet can reach all environments for monitoring and deployment purposes

### What traffic is blocked

- Production cannot initiate connections to development or staging — data must never flow backwards through environments
- Development and staging cannot reach the production database directly
- Partners have no access to any internal subnet beyond the DMZ
- No direct internet access from production — all outbound traffic goes through a controlled egress point

### Preventing misconfiguration

The main risk in network design is overly permissive rules added to unblock something quickly and never removed. A default-deny policy at the network level means that nothing is allowed unless explicitly permitted — any new connection requires a deliberate decision rather than relying on the absence of a blocking rule. This is enforced through Kubernetes NetworkPolicies, documented separately.

---

## Environment Isolation

Development, staging, and production must be completely isolated from each other. The main reasons are:

- **Stability** — a broken deployment in development cannot affect production traffic
- **Security** — production credentials and data are never accessible from development environments where security controls may be looser
- **Compliance** — many regulatory frameworks require demonstrable isolation between environments where sensitive data is processed

The only permitted cross-environment communication is controlled and unidirectional: deployment pipelines push artifacts from development through staging to production, never the other way around.