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

- Development can reach the internet for package downloads and external APIs, and can communicate with staging for artifact promotion through the CI/CD pipeline
- DMZ can receive inbound traffic from the internet on ports 80 and 443 only
- DMZ can forward traffic to production services on defined internal ports
- Partners can reach specific DMZ endpoints only, with no access to internal subnets
- Management can reach all internal environments for monitoring and deployment purposes, and has controlled outbound internet access for CI/CD runners, image pulls, and external alerting — no inbound internet traffic is permitted directly to this subnet

### What traffic is blocked

- Production cannot initiate connections to development or staging — data must never flow backwards through environments
- Development and staging cannot reach the production environment directly
- Partners have no access to any internal subnet beyond the DMZ
- No direct inbound internet access to any subnet other than the DMZ — all external entry points are funnelled through it
- No direct outbound internet access from production or staging — all egress goes through a controlled proxy or NAT gateway
- Management subnet does not accept inbound connections from the internet

### Preventing misconfiguration

The main risk in network design is overly permissive rules added to unblock something quickly and never removed. A default-deny policy at the network level means that nothing is allowed unless explicitly permitted — any new connection requires a deliberate decision rather than relying on the absence of a blocking rule. This is enforced through Kubernetes NetworkPolicies, documented separately.

---

## Environment Isolation

Development, staging, and production must be completely isolated from each other at the network level. The main reasons are:

- **Stability** — a broken deployment in development cannot affect production traffic
- **Security** — production credentials and data are never accessible from development environments where security controls may be looser
- **Compliance** — many regulatory frameworks require demonstrable isolation between environments where sensitive data is processed

The only permitted cross-environment communication is controlled and unidirectional: deployment pipelines in the management subnet push artifacts from development through staging to production, never the other way around. Direct network connectivity between environments is not permitted at any point in this flow.

If staging requires realistic data for validation purposes, the correct approach is to generate synthetic data or run an anonymization process that exports a sanitized copy of production data through the CI/CD pipeline. Staging should never have direct network connectivity to production — even read-only access creates a path that could expose sensitive data to an environment with looser security controls.

---

## Management Subnet

The management subnet (`10.0.20.0/24`) is the only subnet with access to all environments. It hosts internal tooling that needs visibility across the entire infrastructure: CI/CD runners that push deployments, monitoring agents that collect metrics from all environments, logging infrastructure, and administrative access for the operations team.

This broad internal access is a deliberate trade-off. Centralizing operational tooling in a single subnet makes it easier to apply strict controls in one place rather than opening cross-environment access from multiple locations. Outbound internet access is necessary for CI/CD runners to pull images from Docker Hub, interact with GitHub Actions, and download dependencies. This egress is controlled and outbound only — no inbound connections from the internet are permitted to this subnet. The management subnet compensates for its elevated privilege with stronger access controls: only specific machines should be on this subnet, access to it from other subnets should require VPN or jump host authentication, and all activity should be logged.

The main risk of this design is that the management subnet becomes a high-value target. If an attacker gains access to it, they have a foothold with visibility across all environments. Mitigations include strict authentication requirements to reach management hosts, network-level restrictions on which IPs can originate traffic from this subnet, and monitoring for unusual lateral movement.

---

## Security Analysis

### What could go wrong

**Misconfigured firewall rules** — the most common failure mode. A rule added hastily to unblock something in production and never reviewed can silently allow traffic that should be restricted. Over time, exceptions accumulate and the intended segmentation exists only on paper.

**Compromised host in the DMZ** — the DMZ is intentionally exposed to the internet, making it the most likely entry point for an attacker. If an Nginx instance or load balancer is compromised, the attacker has a foothold inside the network with a path toward production services. The DMZ should be treated as untrusted: traffic from the DMZ to production should be validated and limited to the minimum necessary ports and protocols.

**Lateral movement from development** — development environments tend to have looser security controls, more experimental software, and developer credentials that may be reused. If development can reach other subnets beyond what the pipeline requires, a compromised development machine becomes an entry point to the rest of the network.

**Overprivileged partners** — external partners and contractors are often granted more access than strictly necessary to avoid support overhead. A partner account with broad access to internal systems is a significant risk, particularly since third-party security posture is outside the organization's control.

**Management subnet exposure** — the management subnet has privileged access everywhere and outbound internet connectivity. Any weakness in its security controls has organization-wide impact, and a compromised CI/CD runner could be used to push malicious deployments to any environment.

### Mitigations

- Apply default-deny NetworkPolicies in every namespace from the start, before any services are deployed. Adding policies retroactively to a running environment is error-prone.
- Review firewall and network policy rules on a regular schedule. Any rule without a documented reason and owner should be removed.
- Treat the DMZ as a hostile zone. Validate all traffic entering from it, apply rate limiting, and monitor for anomalous patterns.
- Enforce MFA for all access to the management subnet and require a jump host or VPN rather than direct connectivity.
- Apply the principle of least privilege to partner access — provide access only to the specific endpoints they need, with time-limited credentials where possible.
- Restrict outbound internet access from the management subnet to known endpoints (Docker Hub, GitHub) rather than allowing unrestricted egress.
- Maintain audit logs for all cross-subnet traffic and set up alerts for connections that violate the intended segmentation policy.