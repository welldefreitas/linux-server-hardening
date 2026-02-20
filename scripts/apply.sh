#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_root

DRY_RUN="${DRY_RUN:-0}"
SSH_PORT="${SSH_PORT:-22}"
ALLOW_PASSWORD_AUTH="${ALLOW_PASSWORD_AUTH:-false}"
ALLOW_HTTP="${ALLOW_HTTP:-false}"
ALLOW_HTTPS="${ALLOW_HTTPS:-false}"

# Cloud-friendly: keep reboots off by default (avoid surprise downtime)
AUTO_REBOOT="${AUTO_REBOOT:-false}"

# ---- OS detection (Ubuntu 22.04/24.04 Cloud target) ----
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
else
  err "Cannot detect OS (/etc/os-release missing)."
  exit 1
fi

if [[ "${ID:-}" != "ubuntu" ]]; then
  warn "This baseline is optimized for Ubuntu 22.04/24.04 cloud. Detected: ${ID:-unknown}. Proceed carefully."
fi

log "Apply hardening baseline (DRY_RUN=${DRY_RUN})"
log "OS: ${NAME:-unknown} ${VERSION_ID:-unknown} (${VERSION_CODENAME:-unknown})"
log "Config: SSH_PORT=${SSH_PORT} ALLOW_PASSWORD_AUTH=${ALLOW_PASSWORD_AUTH} AUTO_REBOOT=${AUTO_REBOOT} ALLOW_HTTP=${ALLOW_HTTP} ALLOW_HTTPS=${ALLOW_HTTPS}"

# Guardrails (Cloud):
# - Ensure you have console/out-of-band access before changing SSH.
if [[ -n "${SSH_CONNECTION:-}" ]]; then
  log "Detected SSH session. Cloud guardrail: keep an out-of-band console (provider console/serial) available."
fi

# Backup first
if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would run backup snapshot"
else
  bash "${ROOT_DIR}/scripts/backup.sh"
fi

# 1) APT unattended upgrades (Ubuntu cloud signal)
APT_DIR="/etc/apt/apt.conf.d"
APT_20="${ROOT_DIR}/hardening/apt/20auto-upgrades"
APT_50="${ROOT_DIR}/hardening/apt/50unattended-upgrades"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would configure unattended upgrades in ${APT_DIR}"
else
  ensure_dir "${APT_DIR}"
  write_file_if_changed "${APT_20}" "${APT_DIR}/20auto-upgrades"

  # Inject AUTO_REBOOT into 50unattended-upgrades
  tmp_apt="$(mktemp)"
  if [[ "${AUTO_REBOOT}" == "true" ]]; then
    sed -e 's/Unattended-Upgrade::Automatic-Reboot "false";/Unattended-Upgrade::Automatic-Reboot "true";/g' \
      "${APT_50}" > "${tmp_apt}"
  else
    cp -a "${APT_50}" "${tmp_apt}"
  fi
  write_file_if_changed "${tmp_apt}" "${APT_DIR}/50unattended-upgrades"
  rm -f "${tmp_apt}"

  systemctl enable --now unattended-upgrades >/dev/null 2>&1 || true
  log "Unattended upgrades configured."
fi

# 2) SSH hardening (drop-in config)
SSH_DST_DIR="/etc/ssh/sshd_config.d"
SSH_DST_FILE="${SSH_DST_DIR}/99-hardening.conf"
SSH_TEMPLATE="${ROOT_DIR}/hardening/ssh/sshd_config.d/99-hardening.conf"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY_RUN: would install SSH hardening drop-in -> ${SSH_DST_FILE}"
else
  ensure_dir "${SSH_DST_DIR}"
  tmp="$(mktemp)"
  sed \
    -e "s/__SSH_PORT__/${SSH_PORT}/g" \
    -e "s/__PASSWORD_AUTH__/${ALLOW_PASSWORD_AUTH}/g" \
    "${SSH_TEMPLATE}" > "${tmp}"

  write_file_if_changed "${tmp}" "${SSH_DST_FILE}"
  rm -f "${tmp}"

  # Validate before restart (critical anti-lockout step)
  if has_cmd sshd; then
    sshd -t
    log "sshd config validation: OK"
  else
    warn "sshd binary not found; cannot validate config."
  fi

  restart_service_safe "ssh"
fi

# Cloud-init guardrail:
# Cloud-init can override SSH password auth depending on image settings.
# We do not modify cloud-init by default, but we alert if it seems to re-enable SSH password auth.
if [[ -f /etc/cloud/cloud.cfg ]]; then
  if grep -Eq '^\s*ssh_pwauth:\s*true' /etc/cloud/cloud.cfg; then
    warn "cloud-init: ssh_pwauth is TRUE. It may re-enable password auth after reboot. Consider setting ssh_pwauth: false in your image baseline."
  fi
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

# 6) UFW baseline (cloud-compatible)
# Reminder: Cloud Security Groups/Firewall still apply. Ensure SG allows SSH_PORT.
if has_cmd ufw; then
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY_RUN: would configure UFW (default deny incoming, allow SSH:${SSH_PORT}, optional http/https)"
  else
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing

    # Allow SSH port explicitly (works even if OpenSSH profile changes)
    ufw allow "${SSH_PORT}/tcp"

    if [[ "${ALLOW_HTTP}" == "true" ]]; then
      ufw allow 80/tcp
    fi
    if [[ "${ALLOW_HTTPS}" == "true" ]]; then
      ufw allow 443/tcp
    fi

    ufw logging on
    ufw --force enable
    log "UFW configured and enabled."
  fi
else
  warn "ufw not installed. Skipping firewall configuration."
fi

# 7) AppArmor status (Ubuntu cloud standard)
if has_cmd aa-status; then
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY_RUN: would verify AppArmor status"
  else
    aa-status >/dev/null 2>&1 && log "AppArmor: enabled" || warn "AppArmor: not enabled"
  fi
fi

log "Baseline apply completed."
log "Next: run 'sudo bash scripts/audit.sh' to verify state."
