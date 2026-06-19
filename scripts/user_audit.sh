#! /usr/bin/env bash 

# HEADER GAURD
set -euo pipefail
IFS=$'\n\t'

LOG_FILE=/tmp/usr_audit_$(date +%Y%m%d_%H%M%S).log

log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_uid0_accounts() {
    log "Checking for UID 0 (root-equivalent) accounts..."
    awk -F: '$3 == 0 {print $1}' /etc/passwd | while read -r user; do
        log "  Found UID 0 account: $user"
    done
}

check_world_writable() {
    local target_dir="${1}"
    log "Scanning for world-writable files in: $target_dir..."
    { find "$target_dir" -type f -perm -o+w 2>/dev/null || true; } | while read -r file; do
        log "  SECURITY WARNING: World-writable file found: $file"
    done
}

check_home_permissions() {
    log "Checking permissions of user directories under /home..."
    for dir in /home/*/; do
        local clean_dir="${dir%/}"
        if [[ ! -d "$clean_dir" ]]; then
            continue
        fi
        local perms
        perms=$(stat -c "%a" "$clean_dir")
        log "  Directory: $clean_dir | Permissions: $perms"
    done
}

main() {
    log "========================================="
    log "Starting Security Audit..."
    log "========================================="
    
    check_uid0_accounts
    check_world_writable "/home"
    check_home_permissions
    
    log "========================================="
    log "Audit Complete. Log saved to: $LOG_FILE"
    log "========================================="
}

main "$@"
