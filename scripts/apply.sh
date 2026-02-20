#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_root

# ---- Runtime options (override via env) ----
DRY_RUN="${DRY_RUN:-0}"
SSH_PORT="${SSH_PORT:-22}"
ALLOW_PASSWORD_AUTH="${ALLOW_PASSWORD_AUTH:-false}"
ALLOW_HTTP="${ALLOW_HTTP:-false}"
ALLOW_HTTPS="${ALLOW_HTTPS:-false}"

log "Apply hardening baseline (DRY_RUN=${DRY_RUN})"
log "Config: SSH_PORT=${SSH_PORT} ALLOW_PASSWORD_AUTH=${ALLOW_PASSWORD_AUTH} ALLOW_HTTP=${ALLOW_HTTP} ALLOW_HTTPS=${ALLOW_HTTPS}"

# Guardrail: If we disable password auth, ensure current SSH session is likely key-based.
# This is not perfect, but it reduces accidental lockouts.
if [[ "${ALLOW_PASSWORD_AUTH}" != "true" ]]; then
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    log "Detected SSH session. Ensure you have key-based auth working before disabling passwords."
  fi
fi

# 1) Backup first
if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would run backup snapshot"
else
  bash "${ROOT_DIR}/scripts/backup.sh"
fi

# 2) SSH hardening (drop-in config)
SSH_DST_DIR="/etc/ssh/sshd_config.d"
SSH_DST_FILE="${SSH_DST_DIR}/99-hardening.conf"
SSH_TEMPLATE="${ROOT_DIR}/hardening/ssh/sshd_config.d/99-hardening.conf"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would install SSH hardening drop-in -> ${SSH_DST_FILE}"
else
  ensure_dir "${SSH_DST_DIR}"
  # Inject runtime values (SSH_PORT, ALLOW_PASSWORD_AUTH) into a temp file
  tmp="$(mktemp)"
  sed \
    -e "s/__SSH_PORT__/${SSH_PORT}/g" \
    -e "s/__PASSWORD_AUTH__/${ALLOW_PASSWORD_AUTH}/g" \
    "${SSH_TEMPLATE}" > "${tmp}"

  write_file_if_changed "${tmp}" "${SSH_DST_FILE}"
  rm -f "${tmp}"

  # Validate before restart
  if has_cmd sshd; then
    sshd -t
    log "sshd config validation: OK"
  else
    warn "sshd binary not found; cannot validate config."
  fi

  restart_service_safe "ssh"
fi

# 3) sysctl baseline
SYSCTL_DST="/etc/sysctl.d/99-hardening.conf"
SYSCTL_TEMPLATE="${ROOT_DIR}/hardening/sysctl.d/99-hardening.conf"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would install sysctl baseline -> ${SYSCTL_DST}"
else
  write_file_if_changed "${SYSCTL_TEMPLATE}" "${SYSCTL_DST}"
  sysctl --system >/dev/null
  log "Applied sysctl settings."
fi

# 4) auditd rules
AUDIT_DST="/etc/audit/rules.d/99-hardening.rules"
AUDIT_TEMPLATE="${ROOT_DIR}/hardening/auditd/rules.d/99-hardening.rules"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would install auditd rules -> ${AUDIT_DST}"
else
  ensure_dir "/etc/audit/rules.d"
  write_file_if_changed "${AUDIT_TEMPLATE}" "${AUDIT_DST}"
  restart_service_safe "auditd"
fi

# 5) fail2ban sshd jail
F2B_DST="/etc/fail2ban/jail.d/sshd.local"
F2B_TEMPLATE="${ROOT_DIR}/hardening/fail2ban/jail.d/sshd.local"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would install fail2ban sshd jail -> ${F2B_DST}"
else
  ensure_dir "/etc/fail2ban/jail.d"
  write_file_if_changed "${F2B_TEMPLATE}" "${F2B_DST}"
  restart_service_safe "fail2ban"
fi

# 6) UFW firewall baseline
if has_cmd ufw; then
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY_RUN: would configure UFW (default deny incoming, allow SSH:${SSH_PORT}, optional http/https)"
  else
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow "${SSH_PORT}/tcp"

    if [[ "${ALLOW_HTTP}" == "true" ]]; then
      ufw allow 80/tcp
    fi
    if [[ "${ALLOW_HTTPS}" == "true" ]]; then
      ufw allow 443/tcp
    fi

    ufw --force enable
    log "UFW configured and enabled."
  fi
else
  warn "ufw not installed. Skipping firewall configuration."
fi

log "Baseline apply completed."
log "Next: run 'sudo bash scripts/audit.sh' to verify state."
