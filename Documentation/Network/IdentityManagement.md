# Identity Management

## Authentication vs Authorization

Authentication and authorization are two distinct concepts that are often confused because they work together, but they answer different questions.

Authentication is the process of verifying who you are. When you enter a username and password, present a certificate, or use a hardware token, the system is checking that you are who you claim to be. It does not yet decide what you are allowed to do — it only establishes your identity. A successful authentication means "we know who this is."

Authorization is what happens after authentication. Once the system knows who you are, it decides what you are allowed to access or do. A developer authenticated to the company systems may be authorized to access the development environment but not the production database. Authorization is enforced through roles, permissions, and policies applied to authenticated identities. A successful authorization means "this person is allowed to do this specific thing."

The distinction matters in practice because failures in each have different causes and mitigations. An authentication failure means credentials are wrong or compromised. An authorization failure means the permission model is too permissive or misconfigured.

---

## Centralized Identity

### The problem

Without centralized identity, each application manages its own user accounts. A company with 20 people and 10 internal tools means 200 separate account pairs to manage. When someone joins, an admin creates 10 accounts. When someone leaves, all 10 must be disabled — miss one, and a former employee still has access. Password policies, account expiry, and access reviews become impossible to enforce consistently.

Centralized identity solves this by storing all user accounts and group memberships in a single directory. Applications delegate authentication and authorization decisions to that directory rather than managing their own user stores.

### LDAP

LDAP (Lightweight Directory Access Protocol) is the standard protocol for querying and modifying directory services. It defines how clients communicate with a directory server to look up users, groups, and attributes. Most identity infrastructure — from Active Directory to OpenLDAP — speaks LDAP. It is not a product but a protocol, in the same way HTTP is a protocol for the web.

An LDAP directory organizes entries in a tree structure. Users, groups, and other objects live at specific paths in the tree, called Distinguished Names (DNs). An application authenticating a user sends the credentials to the LDAP server, which checks them against the directory and returns whether the authentication succeeded and what groups the user belongs to.

### Active Directory

Active Directory (AD) is Microsoft's implementation of a directory service, built on LDAP and Kerberos. It is the dominant identity solution in enterprise environments, particularly those with Windows infrastructure. Beyond basic user and group management, AD provides Group Policy (centralized configuration management for Windows machines), single sign-on across Windows services, and integration with a large ecosystem of enterprise software.

For organizations already using Windows infrastructure, Active Directory is often the default choice. Its main limitations are cost (it requires Windows Server licenses), complexity, and the fact that it is optimized for Windows environments — integrating Linux systems or cloud-native applications requires additional tooling.

### SSO — Single Sign-On

SSO allows a user to authenticate once and gain access to multiple applications without re-entering credentials. After logging in to the identity provider, the user receives a token or session that other applications trust. This improves both security and usability: users are less likely to reuse weak passwords when they only need to remember one, and the number of authentication events that need to be monitored and secured is reduced.

SSO is typically implemented on top of protocols like SAML or OpenID Connect, which define how identity providers and applications exchange authentication information. Most modern SaaS tools support at least one of these, making SSO feasible even for organizations with a mix of internal and external applications.

---

## Identity Recommendation for GreenDevCorp

With 20+ people and a mix of developers, data analysts, and operations staff, GreenDevCorp is at the size where manual account management starts to become a real operational risk. The recommendation is to adopt a cloud-based identity provider — specifically one that supports LDAP, SSO, and modern protocols like OpenID Connect out of the box.

**Recommended approach: a managed identity provider such as Okta, Azure AD, or Google Workspace Identity.**

The reasoning is straightforward. Building and maintaining an internal LDAP server or Active Directory instance requires dedicated operational effort — patching, backups, high availability, and ongoing administration. For a 20-person company, this overhead is disproportionate. A managed provider handles all of that, offers built-in SSO integration for most SaaS tools the team already uses, and provides MFA enforcement, audit logs, and access reviews out of the box.

### Trade-offs

The main trade-off is vendor dependency and cost. A managed identity provider introduces a monthly cost per user and creates a dependency on an external service — if the provider has an outage, authentication across all integrated applications is affected. Migrating away from a provider later is possible but involves effort.

For an organization prioritizing security and operational simplicity at this stage, the trade-off is worth it. An internal OpenLDAP setup would be cheaper in licensing cost but more expensive in operational time, and it would lack the security features a managed provider includes by default.

As GreenDevCorp grows and potentially comes under compliance requirements, having a centralized identity system with audit trails and access reviews already in place will be significantly easier than retrofitting one later.