# Core Network Services — DNS, DHCP, NTP

## DNS — Domain Name System

DNS is the system that translates human-readable names like `api.greendevo.com` into IP addresses that computers use to communicate. Without it, every device and application would need to know the exact IP address of every service it wants to reach — and those addresses change. DNS acts as a distributed phonebook: you ask it for a name, it gives you the corresponding address.

For an organization, DNS is essential for two reasons. Internally, it allows services and devices to reference each other by name rather than IP, which means changing the address of a server does not require updating every application that talks to it. Externally, it controls how the rest of the internet reaches the organization's public services. Without DNS, deploying or moving any service would require manually reconfiguring every client that depends on it.

### How it works

When a device needs to resolve a name, it sends a query to a DNS resolver — usually one configured automatically by the network. If the resolver does not have the answer cached, it works its way up through the DNS hierarchy: from root servers, to the authoritative name server for the domain, to the final record. The result is cached for a period defined by the record's TTL (time to live) to reduce repeated lookups.

---

## DHCP — Dynamic Host Configuration Protocol

DHCP automatically assigns network configuration to devices when they connect to a network — primarily an IP address, but also the subnet mask, default gateway, and DNS server addresses. Without DHCP, every device would need to be manually configured with a static IP, which does not scale beyond a handful of machines.

In an organization, DHCP eliminates the operational overhead of tracking which IP is assigned to which device. When a laptop connects to the office network, DHCP hands it a valid configuration instantly. When it disconnects, the address is returned to the pool and can be reused. For servers and infrastructure that must always be reachable at the same address, static IPs or DHCP reservations are used instead — DHCP can be configured to always give the same address to a specific device based on its MAC address.

### How it works

When a device joins a network it broadcasts a discovery message. The DHCP server responds with an offer containing an available IP address and configuration. The device requests the offered address, and the server confirms the lease — a time-limited assignment after which the device must renew or release it. This four-step process (Discover, Offer, Request, Acknowledge) happens automatically and takes milliseconds.

---

## NTP — Network Time Protocol

NTP keeps the clocks of all devices in a network synchronized to a common time source. This sounds trivial but is critical for both security and operations. Authentication systems, encryption protocols, and log correlation all depend on accurate, consistent timestamps across systems.

For security, many authentication mechanisms — including Kerberos and certificate validation — reject requests if the timestamp differs by more than a few minutes from the expected time. An attacker who can manipulate a system's clock can potentially replay authentication tokens or invalidate certificates. For operations, when something goes wrong across multiple systems, logs with inconsistent timestamps make it nearly impossible to reconstruct the sequence of events. A five-second drift between two servers can make a log analysis completely unreliable.

### How it works

NTP operates in a hierarchy called strata. Stratum 0 devices are high-precision time sources like atomic clocks or GPS receivers. Stratum 1 servers synchronize directly from them. Stratum 2 servers synchronize from Stratum 1, and so on. Most organization devices synchronize from a Stratum 2 or 3 server, which provides more than sufficient accuracy for operational purposes. The protocol continuously measures round-trip latency and adjusts for network delay to maintain accuracy.