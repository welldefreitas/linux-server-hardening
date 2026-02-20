#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_root

log "Auditing Ubuntu cloud hardening state (no changes)."

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  log "OS: ${NAME:-unknown} ${VERSION_ID:-unknown} (${VERSION_CODENAME:-unknown})"
fi

# SSH effective config
if has_cmd sshd; then
  log "SSH: effective configuration (key fields)..."
  sshd -T 2>/dev/null | grep -Ei "^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|maxauthtries|logingracetime|clientaliveinterval|clientalivecountmax|pubkeyauthentication|allowtcpforwarding|x11forwarding)\b" || true
else
  warn "sshd not found; skipping SSH audit."
fi

# Cloud-init flags that may affect SSH
if [[ -f /etc/cloud/cloud.cfg ]]; then
  log "cloud-init: checking SSH-related flags..."
  grep -En '^[[:space:]]*(ssh_pwauth|disable_root|users):' /etc/cloud/cloud.cfg || true
fi

# Firewall
if has_cmd ufw; then
  log "UFW status:"
  ufw status verbose || true
else
  warn "ufw not installed."
fi

# sysctl key checks
log "sysctl key checks:"
sysctl net.ipv4.conf.all.rp_filter 2>/dev/null || true
sysctl net.ipv4.tcp_syncookies 2>/dev/null || true
sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null || true
sysctl net.ipv4.conf.all.send_redirects 2>/dev/null || true

# auditd
log "auditd status:"
if systemctl is-active auditd >/dev/null 2>&1; then
  log "auditd: active"
else
  warn "auditd: not active"
fi
if has_cmd auditctl; then
  auditctl -l | head -n 60 || true
fi

# fail2ban
log "fail2ban status:"
if systemctl is-active fail2ban >/dev/null 2>&1; then
  log "fail2ban: active"
else
  warn "fail2ban: not active"
fi
if has_cmd fail2ban-client; then
  fail2ban-client status sshd 2>/dev/null || true
fi

# unattended upgrades
log "unattended-upgrades:"
if systemctl is-enabled unattended-upgrades >/dev/null 2>&1; then
  log "unattended-upgrades: enabled"
else
  warn "unattended-upgrades: not enabled"
fi

if systemctl is-active unattended-upgrades >/dev/null 2>&1; then
  log "unattended-upgrades: active"
else
  warn "unattended-upgrades: not active"
fi

if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]]; then
  log "APT periodic config:"
  cat /etc/apt/apt.conf.d/20auto-upgrades || true
else
  warn "Missing /etc/apt/apt.conf.d/20auto-upgrades"
fi

# AppArmor
if has_cmd aa-status; then
  if aa-status >/dev/null 2>&1; then
    log "AppArmor: enabled"
  else
    warn "AppArmor: not enabled"
  fi
fi

log "Audit completed."
