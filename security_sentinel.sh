#!/bin/bash

# =================================================================
# Script Name: security_sentinel.sh
# Description: Cross-Platform Network Recon and Auth-Failure Monitor
# Author: Aaron V. Kempley (IT135 Student / NSC)
# =================================================================

# --- 1. CONFIGURATION & FILES ---
BAN_LIST="banned_ips.txt"
touch "$BAN_LIST"

SAFE_LIST="127.0.0.1,192.168.1.1" 
BAN_LEASE="3600"

LOG_FILE="security_audit.log"
touch "$LOG_FILE"

FAIL_THRESHOLD=5              
KNOWN_GOOD_PORTS="22,80,443,5000/tcp"  
SCAN_TARGET="127.0.0.1"       

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

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

# --- 4. PHASE 3: IPS (Moved up so other functions can find it) ---
ban_ip() {
    local target_ip=$1
    if [[ "$SAFE_LIST" == *"$target_ip"* ]]; then
        echo -e "${GREEN}[V] Skipping Safe-Listed IP: $target_ip${NC}"
        return
    fi

    echo -e "${RED}[!] BANNING IP: $target_ip for $((BAN_LEASE / 60)) minutes...${NC}"
    
    if [[ "$PLATFORM" == "linux" ]]; then
        iptables -A INPUT -s "$target_ip" -j DROP
        echo "$(date): BANNED $target_ip" >> "$LOG_FILE"
        (
            sleep "$BAN_LEASE"
            iptables -D INPUT -s "$target_ip" -j DROP
            echo "$(date): UNBANNED $target_ip (Lease Expired)" >> "$LOG_FILE"
        ) & 
    elif [[ "$PLATFORM" == "mac" ]]; then
        echo -e "${RED}[SIMULATION] macOS: $target_ip added to blocklist for $((BAN_LEASE / 60))m.${NC}"
        echo "$(date): MAC-LOG: Ban requested for $target_ip" >> "$LOG_FILE"
    fi
}

# --- 5. PHASE 1: RECONNAISSANCE ---
run_recon_scan() {
    echo -e "${GREEN}[*] Phase 1: Running Network Reconnaissance on $SCAN_TARGET...${NC}"
    current_ports=$(nmap -F $SCAN_TARGET | grep "open" | awk '{print $1}' | paste -sd "," - | xargs)
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

# --- 6. PHASE 2: AUTH-FAILURE MONITOR ---
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

    if [ "$failed_count" -gt "$FAIL_THRESHOLD" ]; then
        echo -e "${RED}[!] ALERT: High failures detected! Collecting IPs...${NC}"
        if [[ "$PLATFORM" == "mac" ]]; then
            attacker_ip=$(log show --style syslog --last 15m --predicate 'eventMessage CONTAINS "Authentication failed"' 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
            if [ -z "$attacker_ip" ]; then
                attacker_ip="127.0.0.1"
            fi
        else
            attacker_ip=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n 1)
        fi

        if [ -n "$attacker_ip" ]; then
            ban_ip "$attacker_ip"
        else
            echo -e "${RED}[!] Could not resolve attacker IP address.${NC}"
        fi
    else
        echo -e "${GREEN}[V] Authentication levels normal.${NC}"
    fi
}

# --- 7. PHASE 4: DASHBOARD SUMMARY ---
display_dashboard() {
    echo -e "\n${GREEN}=== SECURITY SENTINEL DASHBOARD ===${NC}"
    echo "Last Audit: $(date)"
    echo "-----------------------------------"
    unauth_count=$(grep -c "Unauthorized port" "$LOG_FILE")
    total_bans=$(grep -c "BANNED" "$LOG_FILE")
    echo -e "Unauthorized Ports Detected: ${RED}$unauth_count${NC}"
    echo -e "Total Bans Issued:           ${RED}$total_bans${NC}"
    echo "-----------------------------------"
}

# --- 8. MAIN EXECUTION ---
echo -e "${GREEN}[+] Starting Security Sentinel on $PLATFORM...${NC}"
run_recon_scan
echo "------------------------------------------------"
check_auth_failures
display_dashboard
echo -e "${GREEN}[+] Security Sentinel Audit Complete.${NC}"