#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

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
  sshd -T 2>/dev/null | egrep -i "port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|maxauthtries|logingracetime|clientaliveinterval|clientalivecountmax|pubkeyauthentication|allowtcpforwarding|x11forwarding" || true
else
  warn "sshd not found; skipping SSH audit."
fi

# Cloud-init flags that may affect SSH
if [[ -f /etc/cloud/cloud.cfg ]]; then
  log "cloud-init: checking SSH-related flags..."
  egrep -n '^\s*(ssh_pwauth|disable_root|users):' /etc/cloud/cloud.cfg || true
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
systemctl is-active auditd >/dev/null 2>&1 && log "auditd: active" || warn "auditd: not active"
if has_cmd auditctl; then
  auditctl -l | head -n 60 || true
fi

# fail2ban
log "fail2ban status:"
systemctl is-active fail2ban >/dev/null 2>&1 && log "fail2ban: active" || warn "fail2ban: not active"
if has_cmd fail2ban-client; then
  fail2ban-client status sshd 2>/dev/null || true
fi

# unattended upgrades
log "unattended-upgrades:"
systemctl is-enabled unattended-upgrades >/dev/null 2>&1 && log "unattended-upgrades: enabled" || warn "unattended-upgrades: not enabled"
systemctl is-active unattended-upgrades >/dev/null 2>&1 && log "unattended-upgrades: active" || warn "unattended-upgrades: not active"
if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]]; then
  log "APT periodic config:"
  cat /etc/apt/apt.conf.d/20auto-upgrades || true
else
  warn "Missing /etc/apt/apt.conf.d/20auto-upgrades"
fi

# AppArmor
if has_cmd aa-status; then
  aa-status >/dev/null 2>&1 && log "AppArmor: enabled" || warn "AppArmor: not enabled"
fi

log "Audit completed."
