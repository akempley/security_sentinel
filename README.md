# Security Sentinel: Cross-Platform HIDS/IPS Tool
**Author:** AAron V. Kempley  
**Institutional Affiliation:** North Seattle College (Network & Server Administration)  
**Project Scope:** IT135 / IT111 Capstone development  

---

## 🛡️ Project Overview
The **Security Sentinel** is a lightweight, cross-platform Host-Based Intrusion Detection System (HIDS) and Intrusion Prevention System (IPS) written in Bash. It is designed to bridge the gap between automated network reconnaissance and real-time authentication monitoring.

The script is engineered to run seamlessly on both **macOS (Darwin)** and **Linux** environments, adapting its logging and firewall logic based on the host operating system.

## 🚀 Key Features
* **Phase 1: Network Reconnaissance:** Uses `nmap` to audit open ports against a pre-defined security baseline.
* **Phase 2: Authentication Auditing:** * **macOS:** Leverages the Unified Logging System (`log show`) to detect failed password attempts.
    * **Linux:** Monitors `/var/log/auth.log` or `/var/log/secure` for brute-force patterns.
* **Phase 3: Automated Prevention (IPS):** * Identifies attacker IP addresses using Regex.
    * Includes a **Safe-List** (Whitelist) to prevent accidental lockout of administrative IPs.
    * Implements **Ephemeral Banning** (Leases): Automatically unbans IPs after a set duration using background subshells to maintain firewall hygiene.
* **Phase 4: Security Dashboard:** Provides an immediate visual summary of unauthorized activity and active defense actions.

## 🛠️ Technical Implementation
### Cross-Platform Adaptability
The script uses `uname` to identify the environment and toggles between the macOS `log` architecture and Linux `syslog` structures.

### Security Best Practices
* **Root Enforcement:** Ensures the script is run with `sudo` to access network interfaces and system logs.
* **Idempotency:** The script handles file creation (`touch`) and cleanup, ensuring it can be run repeatedly without side effects.
* **Regex Extraction:** Uses advanced `grep -E -o` patterns to isolate IPv4 addresses from complex system log strings.

## 📋 Prerequisites
* **Nmap:** Must be installed on the host system (`brew install nmap` or `apt install nmap`).
* **Privileges:** Requires `sudo` for firewall (iptables/pfctl) and log access.

## 📈 Professional Roadmap
This project serves as a foundation for my transition into **Network and Server Administration**. Future iterations will include:
1.  Full integration with macOS `pfctl` for active packet filtering.
2.  Webhook integration for Slack/Discord real-time security alerts.
3.  Integration with `systemd` timers for persistent background monitoring.

---
*Developed as part of the Network & Server Administration program at North Seattle College.*
