#!/bin/bash

# =================================================================
# Script Name: security_sentinel.sh
# Description: Cross-Platform Network Recon and Auth-Failure Monitor
# Author: Aaron V. Kempley (IT135 Student / NSC)
# =================================================================

# --- 1. COLORS AND CONFIGURATION ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

LOG_FILE="security_audit.log"
FAIL_THRESHOLD=5              
KNOWN_GOOD_PORTS="22,80,443,5000/tcp"  
SCAN_TARGET="127.0.0.1"       

# --- 2. OS DETECTION ---
OS_TYPE=$(uname)
if [[ "$OS_TYPE" == "Darwin" ]]; then
    PLATFORM="mac"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    PLATFORM="linux"
else
    PLATFORM="unknown"
fi

# --- 3. SAFETY CHECKS ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run with sudo/root privileges.${NC}"
   exit 1
fi

# --- 4. PHASE 1: RECONNAISSANCE ---
run_recon_scan() {
    echo -e "${GREEN}[*] Phase 1: Running Network Reconnaissance on $SCAN_TARGET...${NC}"
    
    current_ports=$(nmap -F $SCAN_TARGET | grep "open" | awk '{print $1}' | paste -sd "," -)
    echo "Found open ports: $current_ports"

    if [ -z "$current_ports" ]; then
        echo -e "${GREEN}[V] No open ports detected. High stealth mode.${NC}"
        return
    fi

    IFS=',' read -ra ADDR <<< "$current_ports"
    for port in "${ADDR[@]}"; do
        if [[ "$KNOWN_GOOD_PORTS" == *"$port"* ]]; then
            echo -e "${GREEN}[V] Port $port is AUTHORIZED.${NC}"
        else
            echo -e "${RED}[!] ALERT: Port $port is NOT in the baseline!${NC}"
            echo "$(date): Unauthorized port $port detected" >> "$LOG_FILE"
        fi
    done
}

# --- 5. PHASE 2: AUTH-FAILURE MONITOR ---
check_auth_failures() {
    echo -e "${GREEN}[*] Phase 2: Auditing Authentication Logs...${NC}"
    
    if [[ "$PLATFORM" == "mac" ]]; then
        failed_count=$(log show --style syslog --last 15m --predicate 'eventMessage CONTAINS "Authentication failed"' 2>/dev/null | grep -c "Authentication failed")
    elif [[ "$PLATFORM" == "linux" ]]; then
        if [ -f /var/log/auth.log ]; then
            failed_count=$(grep "Failed password" /var/log/auth.log | wc -l)
        else
            failed_count=$(grep "Failed password" /var/log/secure 2>/dev/null | wc -l)
        fi
    fi

    echo -e "Found $failed_count failed login attempts in the last 15 minutes."

    # The Alert Logic
    if [ "$failed_count" -gt "$FAIL_THRESHOLD" ]; then
        echo -e "${RED}[!] ALERT: High number of failures detected! ($failed_count)${NC}"
        echo "$(date): HIGH AUTH FAILURES: $failed_count" >> "$LOG_FILE"
    else
        echo -e "${GREEN}[V] Authentication levels normal.${NC}"
    fi
}

# --- 6. MAIN EXECUTION ---
echo -e "${GREEN}[+] Starting Security Sentinel on $PLATFORM...${NC}"
run_recon_scan
echo "------------------------------------------------"
check_auth_failures
echo -e "${GREEN}[+] Security Sentinel Audit Complete.${NC}"