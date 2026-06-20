#!/usr/bin/env bash

# Choice: Created scripts/process_monitor.sh to keep process-monitoring concerns
# separate from the general user auditing script (scripts/user_audit.sh).
# This prevents a single script from growing too large and keeps checks modular.

# 1. Safety Headers
set -euo pipefail
IFS=$'\n\t'

# 2. Global Read_Only Constants (UPPERCASE)
# Fix SC2155: Declare and assign separately to preserve exit status of command substitution
LOG_FILE="/tmp/process_monitor_$(date +%Y%m%d_%H%M%S).log"
readonly LOG_FILE

# Fix SC2034: Rename typo DEFAULT_LINIT to DEFAULT_LIMIT and use it dynamically
DEFAULT_LIMIT=5
readonly DEFAULT_LIMIT

# 3. Cleanup & Signal Trap Handler
cleanup() {
	local exit_code=$?
	echo "Exiting with code ${exit_code}"
}
trap cleanup EXIT SIGINT SIGTERM

# 4. Helper Logging & Formatting Functions
# Fix parameter inversion: msg is first argument, level is second (defaulting to INFO)
log() {
	local msg="${1:-}"
	local level="${2:-INFO}"
	# Fix date syntax (removed space after +) and SC2007 (changed $[msg] to ${msg})
	echo -e "[$(date +'%Y%m%d %H:%M:%S')] [${level}] ${msg}" | tee -a "${LOG_FILE}"
}

# 5. List all users with login shells
check_login_capable_accounts() {
	log "Start Checking users Interacitve Shells"
	awk -F: '$7 !~ /(nologin|false)/ {print $1, $7}' /etc/passwd
}

# 6. List Top Processes
check_top_processes() {
	log "Start Checking Top processes"
	# Dynamically use DEFAULT_LIMIT, adding 1 to account for the header line of ps aux
	ps aux --sort=-%mem | head -n "$((DEFAULT_LIMIT + 1))"
}

# 7. List Zombies processes
# Fix function name typo (chek_ -> check_)
check_zombie_processes() {
	log "Start Checking Zombie processes"
	# Fix awk pattern syntax error ($8 ~ ^/Zz/ -> $8 ~ /^[Zz]/)
	# Also print "none found" when no zombies are running
	local zombies
	zombies=$(ps aux | awk '$8 ~ /^[Zz]/')
	if [[ -z "${zombies}" ]]; then
		echo "none found"
	else
		echo "${zombies}"
	fi
}

main () {
	log "Processes Monitor"
	check_login_capable_accounts
	check_top_processes
	check_zombie_processes
}

main "$@"

