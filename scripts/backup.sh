#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_root

ts="$(timestamp)"
dst="${BACKUP_DIR}/${ts}"
ensure_dir "$dst"

log "Creating backup snapshot: $dst"

backup_file "/etc/ssh/sshd_config" "$dst"
backup_file "/etc/ssh/sshd_config.d/99-hardening.conf" "$dst"
backup_file "/etc/sysctl.d/99-hardening.conf" "$dst"
backup_file "/etc/audit/rules.d/99-hardening.rules" "$dst"
backup_file "/etc/fail2ban/jail.d/sshd.local" "$dst"
backup_file "/etc/ufw/ufw.conf" "$dst"
backup_file "/etc/ufw/user.rules" "$dst"
backup_file "/etc/ufw/user6.rules" "$dst"

log "Backup completed."
log "Latest backup: $ts"
