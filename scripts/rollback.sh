#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_root

if [[ ! -d "${BACKUP_DIR}" ]]; then
  err "No backup directory found: ${BACKUP_DIR}"
  exit 1
fi

latest="$(ls -1 "${BACKUP_DIR}" | tail -n 1 || true)"
if [[ -z "${latest}" ]]; then
  err "No backups available."
  exit 1
fi

src="${BACKUP_DIR}/${latest}"
log "Rolling back from latest backup snapshot: ${latest}"

restore_if_present() {
  local file="$1"
  if [[ -f "${src}/$(basename "$file")" ]]; then
    cp -a "${src}/$(basename "$file")" "$file"
    log "Restored: $file"
  else
    warn "Backup not found for: $file"
  fi
}

restore_if_present "/etc/ssh/sshd_config"
restore_if_present "/etc/ssh/sshd_config.d/99-hardening.conf"
restore_if_present "/etc/sysctl.d/99-hardening.conf"
restore_if_present "/etc/audit/rules.d/99-hardening.rules"
restore_if_present "/etc/fail2ban/jail.d/sshd.local"
restore_if_present "/etc/ufw/ufw.conf"
restore_if_present "/etc/ufw/user.rules"
restore_if_present "/etc/ufw/user6.rules"

# Restart services safely
restart_service_safe "ssh"
restart_service_safe "auditd"
restart_service_safe "fail2ban"

if has_cmd ufw; then
  ufw reload || true
fi

log "Rollback completed."
