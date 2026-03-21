#!/bin/bash

# =================================================================
# Script Name: security_sentinel.sh
# Description: Network Recon and Auth-Failure Hardening Tool
# Author: Aaron V. Kempley (IT135 Student / NSC)
# =================================================================

# --- CONFIGURATION ---
LOG_FILE="security_audit.log"
FAIL_THRESHOLD=5              # Number of failed attempts before banning
KNOWN_GOOD_PORTS="22,80,443"  # Ports we expect to be open
SCAN_TARGET="127.0.0.1"       # Start by scanning yourself for safety
BAN_DURATION="1h"             # How long to block an IP (conceptual for now)

# --- COLORS FOR READABILITY ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if the user is running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run with sudo/root privileges.${NC}"
   exit 1
fi

echo -e "${GREEN}[+] Starting Security Sentinel...${NC}"

run_recon_scan() {
    echo -e "${GREEN}[*] Phase 1: Running Network Reconnaissance Scan on $SCAN_TARGET...${NC}"
    
    # Run nmap and use awk to pull out the port and status
    # We use -F for a fast scan
    current_ports=$(nmap -F $SCAN_TARGET | grep "open" | awk '{print $1}' | paste -sd "," -)

    echo "Found open ports: $current_ports"
    
    if [ "$current_ports" == "$KNOWN_GOOD_PORTS" ]; then
        echo -e "${GREEN}[V] Network state matches baseline.${NC}"
    else
        echo -e "${RED}[!] WARNING: Open ports do not match baseline!${NC}"
        echo "Baseline: $KNOWN_GOOD_PORTS | Current: $current_ports" | tee -a $LOG_FILE
    fi
}

run_recon_scan