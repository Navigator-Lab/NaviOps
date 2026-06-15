#!/usr/bin/env bash

# Header Gaurd
set -euo pipefail
IFS=$'\n\t'

LOG_FILE=/tmp/usr_audit_$(date +%Y%m%d_%H%M%S).log

log() {
	echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_uid0_accounts() {
	log "Start Checking User IDs' With Root Privilage (UID 0)"
	echo "========================================"
	awk -F: '$3 == 0 {print $1}' /etc/passwd
}

check_home_world_writable() {
	log "Start Checking Home World Writable Files"
	echo "========================================"
	local target_dir=$1
	find "$target_dir" -perm -o+w -type f 2>/dev/null || true 
}

check_home_permissions () {
	log "start checking home permissions"
	echo "========================================"
	shopt -s nullglob
	for dir in /home/*/; do
		if [ -d $dir ]; then
			stat $dir 2>/dev/null || true
		fi
	done
	shopt -u nullglob
}


main() {
        # 1. بنر البداية
        log "=== STARTING SECURITY USER AUDIT ==="

        # 2. استدعاء الفحوصات بالترتيب وتمرير المعاملات اللازمة
        check_uid0_accounts

        # نمرر المسار /home هنا لتستقبله الدالة كـ $1
        check_home_world_writable "/home"

        check_home_permissions

        # 3. بنر النهاية مع طباعة مسار ملف السجل
        log "=== AUDIT COMPLETED ==="
        log "Log file saved to: $LOG_FILE"
}

# تشغيل السكربت عبر استدعاء الدالة الرئيسية في السطر الأخير
main "$@"
